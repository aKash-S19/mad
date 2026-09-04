/// Book download service for the Libora reading ecosystem.
///
/// Downloads book files from remote URLs using [Dio], tracks progress,
/// supports cancellation, and saves files to local storage. Creates a
/// [Book] object from the downloaded file.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/remote_book_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class BookDownloadService {
  final Dio _dio = Dio();
  static const Uuid _uuid = const Uuid();

  /// Downloads a remote book file.
  ///
  /// [remoteBook] must have a non-null [downloadUrl]. The [onProgress]
  /// callback receives download progress as a double (0.0–1.0).
  /// Returns the local file path on success, or null on failure.
  Future<String?> downloadBook(
    RemoteBook remoteBook, {
    Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (remoteBook.downloadUrl == null) {
      debugPrint('BookDownloadService: no download URL for book');
      return null;
    }

    try {
      // Determine download directory
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir =
          Directory(p.join(dir.path, 'downloads'));
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      // Determine file extension based on remote book file type
      final extension =
          remoteBook.fileType == 'epub' ? 'epub' : 'pdf';
      final fileName = '${remoteBook.id}.$extension';
      final savePath = p.join(downloadsDir.path, fileName);

      // Download with progress tracking
      await _dio.download(
        remoteBook.downloadUrl!,
        savePath,
        options: Options(
          headers: {'Accept': '*/*'},
          followRedirects: true,
          maxRedirects: 5,
        ),
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
        cancelToken: cancelToken,
      );

      return savePath;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint(
            'BookDownloadService: download cancelled for ${remoteBook.id}');
      } else {
        debugPrint(
            'BookDownloadService: DioException - ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('BookDownloadService: downloadBook error: $e');
      return null;
    }
  }

  /// Downloads a remote book and creates a [Book] object from it.
  ///
  /// Combines [downloadBook] with metadata extraction to produce a
  /// complete [Book] ready for the library.
  Future<Book?> downloadAndCreateBook(
    RemoteBook remoteBook, {
    Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final filePath = await downloadBook(
      remoteBook,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );

    if (filePath == null) return null;

    try {
      final fileSize = await File(filePath).length();
      final fileType = remoteBook.fileType == 'epub'
          ? BookFileType.epub
          : BookFileType.pdf;

      return Book(
        id: _uuid.v4(),
        title: remoteBook.title,
        author: remoteBook.author,
        description: remoteBook.description,
        coverUrl: remoteBook.coverUrl,
        filePath: filePath,
        fileType: fileType,
        fileSize: fileSize,
        publisher: remoteBook.publisher,
        publishYear: remoteBook.publishYear,
        language: remoteBook.language,
        isbn: remoteBook.isbn,
        genres: remoteBook.subjects,
        addedAt: DateTime.now(),
        source: BookSource.download,
        sourceUrl: remoteBook.downloadUrl,
        isDownloaded: true,
        isAvailableOffline: true,
      );
    } catch (e) {
      debugPrint(
          'BookDownloadService: downloadAndCreateBook error: $e');
      return null;
    }
  }

  /// Cancels an in-progress download.
  void cancelDownload(CancelToken cancelToken) {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('User cancelled download');
    }
  }

  /// Returns the local file path for a previously downloaded book.
  Future<String?> getDownloadedFilePath(
      RemoteBook remoteBook) async {
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
          'BookDownloadService: getDownloadedFilePath error: $e');
      return null;
    }
  }

  /// Deletes a downloaded book file from local storage.
  Future<bool> deleteDownloadedFile(
      String bookId, BookFileType fileType) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final extension = fileType == BookFileType.epub ? 'epub' : 'pdf';
      final fileName = '$bookId.$extension';
      final filePath =
          p.join(dir.path, 'downloads', fileName);

      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint(
          'BookDownloadService: deleteDownloadedFile error: $e');
      return false;
    }
  }
}
