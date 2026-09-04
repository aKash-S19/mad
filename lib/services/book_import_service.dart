/// Book import service for the Libora reading ecosystem.
///
/// Handles importing book files (PDF/EPUB) from the local filesystem.
/// Extracts metadata (title, author, cover), copies the file to app
/// storage, and creates a [Book] object. Uses [epubx] for EPUB parsing
/// and [path_provider] for storage.
library;

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class BookImportService {
  static const Uuid _uuid = const Uuid();

  /// Imports a book file from the given [filePath].
  ///
  /// Determines the file type (PDF or EPUB), extracts metadata,
  /// copies the file to app storage, and returns a [Book] object.
  static Future<Book> importFile(String filePath) async {
    if (!await File(filePath).exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final extension = p.extension(filePath).toLowerCase();

    if (extension == '.epub') {
      return _importEpub(filePath);
    } else if (extension == '.pdf') {
      return _importPdf(filePath);
    } else {
      throw UnsupportedError(
          'Unsupported file type: $extension. Only .pdf and .epub are supported.');
    }
  }

  /// Imports an EPUB file: extracts metadata, cover image, and chapters.
  static Future<Book> _importEpub(String filePath) async {
    try {
      final epubData = await _extractEpubMetadata(filePath);

      // Copy file to app storage
      final savedPath = await _copyToAppStorage(
        filePath,
        '${epubData.title ?? 'book'}_${_uuid.v4()}.epub',
      );

      // Extract cover if available
      String? coverPath;
      if (epubData.coverImageBytes != null) {
        coverPath = await _saveCoverImage(
          epubData.coverImageBytes!,
          '${_uuid.v4()}.jpg',
        );
      }

      final fileSize = await File(savedPath).length();

      return Book(
        id: _uuid.v4(),
        title: epubData.title ?? p.basenameWithoutExtension(filePath),
        author: epubData.author ?? 'Unknown Author',
        description: epubData.description ?? '',
        coverPath: coverPath,
        filePath: savedPath,
        fileType: BookFileType.epub,
        fileSize: fileSize,
        pageCount: epubData.chapterCount,
        addedAt: DateTime.now(),
        source: BookSource.import,
        isDownloaded: true,
        isAvailableOffline: true,
      );
    } catch (e) {
      debugPrint('BookImportService: _importEpub error: $e');
      rethrow;
    }
  }

  /// Imports a PDF file: extracts basic metadata from the filename
  /// (PDFs don't have standard metadata accessible without a PDF library).
  static Future<Book> _importPdf(String filePath) async {
    try {
      // PDF metadata extraction is limited without a dedicated library.
      // We extract what we can from the filename.
      final fileName = p.basenameWithoutExtension(filePath);
      final fileSize = await File(filePath).length();

      // Copy file to app storage
      final savedPath = await _copyToAppStorage(
        filePath,
        '$fileName_${_uuid.v4()}.pdf',
      );

      // Try to parse title and author from filename
      // Common pattern: "Title - Author.pdf"
      String title = fileName;
      String author = 'Unknown Author';
      if (fileName.contains(' - ')) {
        final parts = fileName.split(' - ');
        title = parts.first.trim();
        if (parts.length > 1) {
          author = parts.last.trim();
        }
      } else if (fileName.contains(' by ')) {
        final parts = fileName.split(' by ');
        title = parts.first.trim();
        if (parts.length > 1) {
          author = parts.last.trim();
        }
      }

      return Book(
        id: _uuid.v4(),
        title: title,
        author: author,
        filePath: savedPath,
        fileType: BookFileType.pdf,
        fileSize: fileSize,
        addedAt: DateTime.now(),
        source: BookSource.import,
        isDownloaded: true,
        isAvailableOffline: true,
      );
    } catch (e) {
      debugPrint('BookImportService: _importPdf error: $e');
      rethrow;
    }
  }

  /// Extracts EPUB metadata (title, author, cover, chapters).
  static Future<_EpubMetadata> _extractEpubMetadata(
      String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final epubReader = EpubReader();

      final epubBook = await epubReader.readBook(bytes);

      final title = epubBook.title;
      final author = epubBook.author;
      final description = epubBook.description;

      // Count chapters from the spine
      int chapterCount = 0;
      if (epubBook.content?.html != null) {
        chapterCount = epubBook.content!.html!.length;
      }

      // Extract cover image
      List<int>? coverBytes;
      if (epubBook.coverImage != null) {
        coverBytes = epubBook.coverImage!.content;
      }

      return _EpubMetadata(
        title: title,
        author: author,
        description: description,
        chapterCount: chapterCount,
        coverImageBytes: coverBytes,
      );
    } catch (e) {
      debugPrint('BookImportService: _extractEpubMetadata error: $e');
      // Return minimal metadata if extraction fails
      return _EpubMetadata(
        title: p.basenameWithoutExtension(filePath),
        author: 'Unknown Author',
      );
    }
  }

  /// Extracts the EPUB cover image as bytes.
  static Future<List<int>?> extractEpubCover(
      String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final epubReader = EpubReader();
      final epubBook = await epubReader.readBook(bytes);
      return epubBook.coverImage?.content;
    } catch (e) {
      debugPrint('BookImportService: extractEpubCover error: $e');
      return null;
    }
  }

  /// Copies a file to the app's documents directory with a new name.
  static Future<String> _copyToAppStorage(
      String sourcePath, String destName) async {
    final dir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(dir.path, 'books'));
    if (!booksDir.existsSync()) {
      booksDir.createSync(recursive: true);
    }

    final destPath = p.join(booksDir.path, destName);
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// Saves cover image bytes to the app's documents directory.
  static Future<String> _saveCoverImage(
      List<int> bytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(dir.path, 'covers'));
    if (!coversDir.existsSync()) {
      coversDir.createSync(recursive: true);
    }

    final coverPath = p.join(coversDir.path, fileName);
    final file = File(coverPath);
    await file.writeAsBytes(bytes);
    return coverPath;
  }

  /// Determines the file type from the file extension.
  static BookFileType? getFileType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.pdf':
        return BookFileType.pdf;
      case '.epub':
        return BookFileType.epub;
      default:
        return null;
    }
  }

  /// Validates that a file is a supported book format.
  static bool isSupportedFile(String filePath) {
    return getFileType(filePath) != null;
  }
}

/// Container for extracted EPUB metadata.
class _EpubMetadata {
  final String? title;
  final String? author;
  final String? description;
  final int chapterCount;
  final List<int>? coverImageBytes;

  const _EpubMetadata({
    this.title,
    this.author,
    this.description,
    this.chapterCount = 0,
    this.coverImageBytes,
  });
}
