/// EPUB parser service for the Libora reading ecosystem.
///
/// Bridges the [epubx] library to our [Chapter] model. Provides methods
/// to parse an EPUB file, extract metadata, table of contents, chapter
/// content, and cover image.
library;

import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';
import 'package:libora/data/models/chapter_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Container for parsed EPUB data.
class EpubData {
  final String? title;
  final String? author;
  final String? description;
  final String? publisher;
  final String? language;
  final List<Chapter> chapters;
  final List<int>? coverImageBytes;
  final String? coverImagePath;

  const EpubData({
    this.title,
    this.author,
    this.description,
    this.publisher,
    this.language,
    this.chapters = const [],
    this.coverImageBytes,
    this.coverImagePath,
  });
}

class EpubParserService {
  static const Uuid _uuid = Uuid();

  /// Parses an EPUB file and extracts all metadata and content.
  ///
  /// Returns an [EpubData] containing the title, author, chapters,
  /// and cover image (if available).
  static Future<EpubData> parseEpub(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);

      final chapters = _extractChapters(epubBook);

      String? coverPath;
      if (epubBook.CoverImage != null) {
        coverPath = await _saveCoverToTemp(
          epubBook.CoverImage!.content!,
        );
      }

      return EpubData(
        title: epubBook.Title,
        author: epubBook.Author,
        description: epubBook.Schema?.Package?.Description,
        publisher: epubBook.Schema?.Package?.Publisher,
        language: epubBook.Schema?.Package?.Language,
        chapters: chapters,
        coverImageBytes: epubBook.CoverImage?.content,
        coverImagePath: coverPath,
      );
    } catch (e) {
      debugPrint('EpubParserService: parseEpub error: $e');
      return const EpubData();
    }
  }

  /// Extracts the table of contents as a list of [Chapter] objects.
  static Future<List<Chapter>> getTOC(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);
      return _extractChapters(epubBook);
    } catch (e) {
      debugPrint('EpubParserService: getTOC error: $e');
      return [];
    }
  }

  /// Extracts and returns the HTML content for a specific chapter
  /// identified by its [href].
  static Future<String> extractChapterContent(
      String filePath, String chapterHref) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);

      final htmlFiles = epubBook.Content?.Html;
      if (htmlFiles == null || htmlFiles.isEmpty) return '';

      for (final htmlFile in htmlFiles.entries) {
        final fileName = htmlFile.key;
        if (fileName.contains(chapterHref) ||
            chapterHref.contains(fileName)) {
          return htmlFile.value.Content ?? '';
        }
      }

      final baseHref =
          chapterHref.split('#').first.split('/').last;
      for (final htmlFile in htmlFiles.entries) {
        if (htmlFile.key.contains(baseHref)) {
          return htmlFile.value.Content ?? '';
        }
      }

      return '';
    } catch (e) {
      debugPrint(
          'EpubParserService: extractChapterContent error: $e');
      return '';
    }
  }

  /// Extracts the cover image bytes from an EPUB file.
  static Future<List<int>?> extractCover(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);
      return epubBook.CoverImage?.content;
    } catch (e) {
      debugPrint('EpubParserService: extractCover error: $e');
      return null;
    }
  }

  /// Extracts metadata (title, author, publisher, language) from an EPUB.
  static Future<EpubData> extractMetadata(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);

      return EpubData(
        title: epubBook.Title,
        author: epubBook.Author,
        description: epubBook.Schema?.Package?.Description,
        publisher: epubBook.Schema?.Package?.Publisher,
        language: epubBook.Schema?.Package?.Language,
      );
    } catch (e) {
      debugPrint('EpubParserService: extractMetadata error: $e');
      return const EpubData();
    }
  }

  static List<Chapter> _extractChapters(EpubBook epubBook) {
    final chapters = <Chapter>[];
    final epubChapters = epubBook.Chapters;

    if (epubChapters != null && epubChapters.isNotEmpty) {
      var order = 0;
      _flattenChapters(epubChapters, chapters, order);
      return chapters;
    }

    final htmlFiles = epubBook.Content?.Html;
    if (htmlFiles != null && htmlFiles.isNotEmpty) {
      var order = 0;
      for (final entry in htmlFiles.entries) {
        final fileName = entry.key;
        final content = entry.value.Content ?? '';
        final title = _extractTitleFromHtml(content) ??
            _humanizeFileName(fileName);

        chapters.add(Chapter(
          id: _uuid.v4(),
          title: title,
          href: fileName,
          order: order,
          level: 0,
        ));
        order++;
      }
    }

    return chapters;
  }

  static void _flattenChapters(
      List<dynamic> epubChapters, List<Chapter> chapters, int order) {
    for (final ch in epubChapters) {
      final title = ch.Title ?? 'Untitled';
      final htmlContent = ch.HtmlContent ?? '';
      final href = _uuid.v4();

      chapters.add(Chapter(
        id: _uuid.v4(),
        title: title,
        href: href,
        order: order,
        level: 0,
      ));
      order++;

      if (ch.SubChapters != null && (ch.SubChapters as List).isNotEmpty) {
        _flattenChapters(ch.SubChapters as List, chapters, order);
      }
    }
  }

  /// Parses EPUB 3 navigation (X)HTML content for chapter list.
  static List<Chapter> _parseNavContent(String navHtml) {
    final chapters = <Chapter>[];

    // Simple regex-based extraction of nav links
    // Pattern: <a href="...">Title</a>
    final navLinkPattern =
        RegExp(r'<a\s+[^>]*href="([^"]*)"[^>]*>(.*?)</a>',
            caseSensitive: false, dotAll: true);

    var order = 0;
    for (final match in navLinkPattern.allMatches(navHtml)) {
      final href = match.group(1) ?? '';
      final titleHtml = match.group(2) ?? '';
      final title = _stripHtmlTags(titleHtml).trim();

      if (title.isNotEmpty && href.isNotEmpty) {
        chapters.add(Chapter(
          id: _uuid.v4(),
          title: title,
          href: href,
          order: order,
          level: 0,
        ));
        order++;
      }
    }

    return chapters;
  }

  /// Parses NCX (EPUB 2 table of contents) XML for chapter list.
  static List<Chapter> _parseNcxContent(String ncxXml) {
    final chapters = <Chapter>[];

    // Pattern: <navPoint> ... <text>Title</text> ... <content src="..."/>
    final navPointPattern = RegExp(
        r'<navPoint[^>]*>.*?<text>(.*?)</text>.*?<content\s+src="([^"]*)"[^>]*/>.*?</navPoint>',
        caseSensitive: false,
        dotAll: true);

    var order = 0;
    for (final match in navPointPattern.allMatches(ncxXml)) {
      final title = _stripHtmlTags(match.group(1) ?? '').trim();
      final src = match.group(2) ?? '';

      if (title.isNotEmpty) {
        chapters.add(Chapter(
          id: _uuid.v4(),
          title: title,
          href: src,
          order: order,
          level: 0,
        ));
        order++;
      }
    }

    return chapters;
  }

  /// Extracts the <title> tag content from an HTML string.
  static String? _extractTitleFromHtml(String html) {
    final titlePattern =
        RegExp(r'<title[^>]*>(.*?)</title>',
            caseSensitive: false, dotAll: true);
    final match = titlePattern.firstMatch(html);
    if (match != null) {
      final title = _stripHtmlTags(match.group(1) ?? '').trim();
      return title.isNotEmpty ? title : null;
    }

    // Try <h1> or <h2>
    final h1Pattern =
        RegExp(r'<h[12][^>]*>(.*?)</h[12]>',
            caseSensitive: false, dotAll: true);
    final h1Match = h1Pattern.firstMatch(html);
    if (h1Match != null) {
      final title = _stripHtmlTags(h1Match.group(1) ?? '').trim();
      return title.isNotEmpty ? title : null;
    }

    return null;
  }

  /// Strips HTML tags from a string.
  static String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  /// Converts a filename to a human-readable chapter title.
  static String _humanizeFileName(String fileName) {
    final name = p.basenameWithoutExtension(fileName);
    // Remove common prefixes like "chapter_"
    final cleaned = name
        .replaceAll(RegExp(r'^(chapter|ch|part)_'), '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
    // Capitalize first letter
    if (cleaned.isEmpty) return fileName;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  /// Saves cover image bytes to a temporary file.
  static Future<String> _saveCoverToTemp(List<int> bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final coversDir =
          Directory(p.join(dir.path, 'epub_covers'));
      if (!coversDir.existsSync()) {
        coversDir.createSync(recursive: true);
      }

      final coverPath =
          p.join(coversDir.path, '${_uuid.v4()}.jpg');
      final file = File(coverPath);
      await file.writeAsBytes(bytes);
      return coverPath;
    } catch (e) {
      debugPrint('EpubParserService: _saveCoverToTemp error: $e');
      return '';
    }
  }
}
