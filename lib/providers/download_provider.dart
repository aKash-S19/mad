/// Download provider for the Libora reading ecosystem.
///
/// Manages book downloads with progress tracking using [Dio]. Supports
/// concurrent downloads, cancellation, a download queue, and tracking
/// completed downloads. Downloaded files are stored using [path_provider].
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:libora/data/models/remote_book_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DownloadProvider extends ChangeNotifier {
  final Dio _dio = Dio();

  /// Active downloads: bookId -> progress (0.0 to 1.0).
  Map<String, double> _activeDownloads = {};
  Map<String, double> get activeDownloads =>
      Map.unmodifiable(_activeDownloads);

  /// Queue of books waiting to download.
  List<RemoteBook> _downloadQueue = [];
  List<RemoteBook> get downloadQueue =>
      List.unmodifiable(_downloadQueue);

  /// Completed download book IDs.
  List<String> _completedDownloads = [];
  List<String> get completedDownloads =>
      List.unmodifiable(_completedDownloads);

  /// Failed downloads: bookId -> error message.
  Map<String, String> _failedDownloads = {};
  Map<String, String> get failedDownloads =>
      Map.unmodifiable(_failedDownloads);

  String? _error;
  String? get error => _error;

  /// Cancel tokens for active downloads.
  final Map<String, CancelToken> _cancelTokens = {};

  /// Downloads a remote book. If another download is in progress,
  /// the book is added to the queue.
  Future<String?> downloadBook(RemoteBook remoteBook) async {
    if (remoteBook.downloadUrl == null) {
      _error = 'No download URL available for this book.';
      notifyListeners();
      return null;
    }

    // Already downloading or completed?
    if (_activeDownloads.containsKey(remoteBook.id) ||
        _completedDownloads.contains(remoteBook.id)) {
      return null;
    }

    // If there are active downloads, queue this one
    if (_activeDownloads.length >= 3) {
      _downloadQueue.add(remoteBook);
      notifyListeners();
      return null;
    }

    return _executeDownload(remoteBook);
  }

  /// Executes the actual download.
  Future<String?> _executeDownload(RemoteBook remoteBook) async {
    final cancelToken = CancelToken();
    _cancelTokens[remoteBook.id] = cancelToken;
    _activeDownloads[remoteBook.id] = 0.0;
    notifyListeners();

    try {
      // Determine download directory
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir =
          Directory(p.join(dir.path, 'downloads'));
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      // Determine file extension
      final extension = remoteBook.fileType == 'epub'
          ? 'epub'
          : 'pdf';
      final fileName =
          '${remoteBook.id}.$extension';
      final savePath = p.join(downloadsDir.path, fileName);

      // Download with progress
      await _dio.download(
        remoteBook.downloadUrl!,
        savePath,
        options: Options(
          headers: {
            'Accept': '*/*',
          },
          followRedirects: true,
          maxRedirects: 5,
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _activeDownloads[remoteBook.id] =
                received / total;
            notifyListeners();
          }
        },
        cancelToken: cancelToken,
      );

      // Mark complete
      _activeDownloads.remove(remoteBook.id);
      _completedDownloads.add(remoteBook.id);
      _cancelTokens.remove(remoteBook.id);
      notifyListeners();

      // Process next in queue
      _processQueue();

      return savePath;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _activeDownloads.remove(remoteBook.id);
        _cancelTokens.remove(remoteBook.id);
        debugPrint(
            'DownloadProvider: download cancelled for ${remoteBook.id}');
      } else {
        _activeDownloads.remove(remoteBook.id);
        _failedDownloads[remoteBook.id] =
            e.message ?? 'Download failed';
        _error = 'Download failed: ${e.message}';
      }
      notifyListeners();
      return null;
    } catch (e) {
      _activeDownloads.remove(remoteBook.id);
      _failedDownloads[remoteBook.id] = e.toString();
      _error = 'Download failed: $e';
      debugPrint('DownloadProvider: _executeDownload error: $e');
      notifyListeners();
      return null;
    }
  }

  /// Cancels an active download by book id.
  void cancelDownload(String id) {
    final cancelToken = _cancelTokens[id];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('User cancelled download');
    }
    _activeDownloads.remove(id);
    _cancelTokens.remove(id);

    // Remove from queue if present
    _downloadQueue.removeWhere((b) => b.id == id);

    notifyListeners();
    _processQueue();
  }

  /// Returns the download progress for a book (0.0 to 1.0), or -1 if
  /// not downloading.
  double getDownloadProgress(String id) {
    if (_activeDownloads.containsKey(id)) {
      return _activeDownloads[id]!;
    }
    if (_completedDownloads.contains(id)) {
      return 1.0;
    }
    return -1.0;
  }

  /// Returns true if the book is currently downloading.
  bool isDownloading(String id) {
    return _activeDownloads.containsKey(id);
  }

  /// Returns true if the book has been downloaded.
  bool isCompleted(String id) {
    return _completedDownloads.contains(id);
  }

  /// Returns the local file path for a downloaded book.
  Future<String?> getDownloadedFilePath(
      RemoteBook remoteBook) async {
    if (!_completedDownloads.contains(remoteBook.id)) return null;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final extension =
          remoteBook.fileType == 'epub' ? 'epub' : 'pdf';
      final fileName = '${remoteBook.id}.$extension';
      final filePath =
          p.join(dir.path, 'downloads', fileName);

      if (await File(filePath).exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint(
          'DownloadProvider: getDownloadedFilePath error: $e');
      return null;
    }
  }

  /// Clears the completed downloads list.
  void clearCompleted() {
    _completedDownloads.clear();
    _failedDownloads.clear();
    notifyListeners();
  }

  /// Processes the next item in the download queue.
  void _processQueue() {
    if (_downloadQueue.isEmpty) return;
    if (_activeDownloads.length >= 3) return;

    final next = _downloadQueue.removeAt(0);
    _executeDownload(next);
  }

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
