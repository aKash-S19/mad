/// Book model for the Libora reading ecosystem.
///
/// Represents a book in the user's library, whether imported from a local file,
/// downloaded from a remote source, or added via URL. Tracks reading progress,
/// metadata, and availability status.
library;

import 'package:flutter/foundation.dart';

/// The file format of the book content.
enum BookFileType { pdf, epub }

/// The reading status of a book in the user's library.
enum ReadingStatus {
  wantToRead,
  currentlyReading,
  completed,
  favorite,
}

/// How the book was added to the user's library.
enum BookSource {
  import,
  download,
  url,
}

/// Extension to convert [BookFileType] to/from string for SQLite storage.
extension BookFileTypeX on BookFileType {
  String get name {
    switch (this) {
      case BookFileType.pdf:
        return 'pdf';
      case BookFileType.epub:
        return 'epub';
    }
  }

  static BookFileType fromString(String? value) {
    switch (value) {
      case 'pdf':
        return BookFileType.pdf;
      case 'epub':
        return BookFileType.epub;
      default:
        return BookFileType.pdf;
    }
  }
}

/// Extension to convert [ReadingStatus] to/from string for SQLite storage.
extension ReadingStatusX on ReadingStatus {
  String get name {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'wantToRead';
      case ReadingStatus.currentlyReading:
        return 'currentlyReading';
      case ReadingStatus.completed:
        return 'completed';
      case ReadingStatus.favorite:
        return 'favorite';
    }
  }

  static ReadingStatus fromString(String? value) {
    switch (value) {
      case 'wantToRead':
        return ReadingStatus.wantToRead;
      case 'currentlyReading':
        return ReadingStatus.currentlyReading;
      case 'completed':
        return ReadingStatus.completed;
      case 'favorite':
        return ReadingStatus.favorite;
      default:
        return ReadingStatus.wantToRead;
    }
  }
}

/// Extension to convert [BookSource] to/from string for SQLite storage.
extension BookSourceX on BookSource {
  String get name {
    switch (this) {
      case BookSource.import:
        return 'import';
      case BookSource.download:
        return 'download';
      case BookSource.url:
        return 'url';
    }
  }

  static BookSource fromString(String? value) {
    switch (value) {
      case 'import':
        return BookSource.import;
      case 'download':
        return BookSource.download;
      case 'url':
        return BookSource.url;
      default:
        return BookSource.import;
    }
  }
}

@immutable
class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String? coverPath;
  final String? coverUrl;
  final String? filePath;
  final BookFileType fileType;
  final int fileSize;
  final int? pageCount;
  final int currentPage;
  final double readingProgress;
  final ReadingStatus readingStatus;
  final DateTime? lastOpenedAt;
  final DateTime addedAt;
  final BookSource source;
  final String? sourceUrl;
  final String? publisher;
  final int? publishYear;
  final String? isbn;
  final String? language;
  final List<String> genres;
  final List<String> tags;
  final bool isDownloaded;
  final bool isAvailableOffline;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.description = '',
    this.coverPath,
    this.coverUrl,
    this.filePath,
    this.fileType = BookFileType.pdf,
    this.fileSize = 0,
    this.pageCount,
    this.currentPage = 0,
    this.readingProgress = 0.0,
    this.readingStatus = ReadingStatus.wantToRead,
    this.lastOpenedAt,
    required this.addedAt,
    this.source = BookSource.import,
    this.sourceUrl,
    this.publisher,
    this.publishYear,
    this.isbn,
    this.language,
    this.genres = const [],
    this.tags = const [],
    this.isDownloaded = false,
    this.isAvailableOffline = false,
  });

  /// Creates a [Book] from a [Map] (typically from SQLite).
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      description: (map['description'] as String?) ?? '',
      coverPath: map['cover_path'] as String?,
      coverUrl: map['cover_url'] as String?,
      filePath: map['file_path'] as String?,
      fileType: BookFileTypeX.fromString(map['file_type'] as String?),
      fileSize: (map['file_size'] as int?) ?? 0,
      pageCount: map['page_count'] as int?,
      currentPage: (map['current_page'] as int?) ?? 0,
      readingProgress: _toDouble(map['reading_progress']),
      readingStatus:
          ReadingStatusX.fromString(map['reading_status'] as String?),
      lastOpenedAt: _parseDate(map['last_opened_at']),
      addedAt: _parseDate(map['added_at']) ?? DateTime.now(),
      source: BookSourceX.fromString(map['source'] as String?),
      sourceUrl: map['source_url'] as String?,
      publisher: map['publisher'] as String?,
      publishYear: map['publish_year'] as int?,
      isbn: map['isbn'] as String?,
      language: map['language'] as String?,
      genres: _parseList(map['genres']),
      tags: _parseList(map['tags']),
      isDownloaded: _toBool(map['is_downloaded']),
      isAvailableOffline: _toBool(map['is_available_offline']),
    );
  }

  /// Converts this [Book] to a [Map] suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'cover_path': coverPath,
      'cover_url': coverUrl,
      'file_path': filePath,
      'file_type': fileType.name,
      'file_size': fileSize,
      'page_count': pageCount,
      'current_page': currentPage,
      'reading_progress': readingProgress,
      'reading_status': readingStatus.name,
      'last_opened_at': lastOpenedAt?.toIso8601String(),
      'added_at': addedAt.toIso8601String(),
      'source': source.name,
      'source_url': sourceUrl,
      'publisher': publisher,
      'publish_year': publishYear,
      'isbn': isbn,
      'language': language,
      'genres': genres.join(','),
      'tags': tags.join(','),
      'is_downloaded': isDownloaded ? 1 : 0,
      'is_available_offline': isAvailableOffline ? 1 : 0,
    };
  }

  /// Creates a copy of this [Book] with the given fields replaced.
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? coverPath,
    String? coverUrl,
    String? filePath,
    BookFileType? fileType,
    int? fileSize,
    int? pageCount,
    int? currentPage,
    double? readingProgress,
    ReadingStatus? readingStatus,
    DateTime? lastOpenedAt,
    DateTime? addedAt,
    BookSource? source,
    String? sourceUrl,
    String? publisher,
    int? publishYear,
    String? isbn,
    String? language,
    List<String>? genres,
    List<String>? tags,
    bool? isDownloaded,
    bool? isAvailableOffline,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverPath: coverPath ?? this.coverPath,
      coverUrl: coverUrl ?? this.coverUrl,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      currentPage: currentPage ?? this.currentPage,
      readingProgress: readingProgress ?? this.readingProgress,
      readingStatus: readingStatus ?? this.readingStatus,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      addedAt: addedAt ?? this.addedAt,
      source: source ?? this.source,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      publisher: publisher ?? this.publisher,
      publishYear: publishYear ?? this.publishYear,
      isbn: isbn ?? this.isbn,
      language: language ?? this.language,
      genres: genres ?? this.genres,
      tags: tags ?? this.tags,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isAvailableOffline: isAvailableOffline ?? this.isAvailableOffline,
    );
  }

  /// Factory constructor to create a [Book] from another [Book] instance,
  /// optionally overriding specific fields. Useful for promoting a
  /// [RemoteBook] to a local [Book].
  factory Book.fromBook(Book other) {
    return Book(
      id: other.id,
      title: other.title,
      author: other.author,
      description: other.description,
      coverPath: other.coverPath,
      coverUrl: other.coverUrl,
      filePath: other.filePath,
      fileType: other.fileType,
      fileSize: other.fileSize,
      pageCount: other.pageCount,
      currentPage: other.currentPage,
      readingProgress: other.readingProgress,
      readingStatus: other.readingStatus,
      lastOpenedAt: other.lastOpenedAt,
      addedAt: other.addedAt,
      source: other.source,
      sourceUrl: other.sourceUrl,
      publisher: other.publisher,
      publishYear: other.publishYear,
      isbn: other.isbn,
      language: other.language,
      genres: List.from(other.genres),
      tags: List.from(other.tags),
      isDownloaded: other.isDownloaded,
      isAvailableOffline: other.isAvailableOffline,
    );
  }

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, '
        'fileType: $fileType, progress: $readingProgress, '
        'status: $readingStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // -- Helpers for parsing from SQLite rows --

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value == '1' || value == 'true';
    return false;
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
