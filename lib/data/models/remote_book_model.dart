/// Remote book model for the Libora reading ecosystem.
///
/// Represents a book returned by a remote API (Open Library, Project Gutenberg,
/// Internet Archive, etc.) during browse/discover operations. This is a
/// read-only representation of a book that the user does not yet have in
/// their local library but can download or add.
library;

import 'package:flutter/foundation.dart';

/// The remote source/API from which a [RemoteBook] was fetched.
enum RemoteBookSource {
  openLibrary,
  gutenberg,
  internetArchive,
}

/// Extension to convert [RemoteBookSource] to/from string.
extension RemoteBookSourceX on RemoteBookSource {
  String get name {
    switch (this) {
      case RemoteBookSource.openLibrary:
        return 'openLibrary';
      case RemoteBookSource.gutenberg:
        return 'gutenberg';
      case RemoteBookSource.internetArchive:
        return 'internetArchive';
    }
  }

  static RemoteBookSource fromString(String? value) {
    switch (value) {
      case 'openLibrary':
        return RemoteBookSource.openLibrary;
      case 'gutenberg':
        return RemoteBookSource.gutenberg;
      case 'internetArchive':
        return RemoteBookSource.internetArchive;
      default:
        return RemoteBookSource.openLibrary;
    }
  }
}

@immutable
class RemoteBook {
  final String id;
  final String title;
  final String author;
  final String description;
  final String? coverUrl;
  final String? downloadUrl;
  final String fileType;
  final int fileSize;
  final RemoteBookSource source;
  final String? publisher;
  final int? publishYear;
  final String? language;
  final List<String> subjects;
  final String? isbn;
  final bool isAvailable;

  const RemoteBook({
    required this.id,
    required this.title,
    this.author = '',
    this.description = '',
    this.coverUrl,
    this.downloadUrl,
    this.fileType = 'pdf',
    this.fileSize = 0,
    this.source = RemoteBookSource.openLibrary,
    this.publisher,
    this.publishYear,
    this.language,
    this.subjects = const [],
    this.isbn,
    this.isAvailable = true,
  });

  /// Creates a [RemoteBook] from a [Map] (typically from a JSON API response).
  factory RemoteBook.fromMap(Map<String, dynamic> map) {
    return RemoteBook(
      id: map['id']?.toString() ?? '',
      title: (map['title'] as String?) ?? '',
      author: (map['author'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      coverUrl: map['cover_url'] as String?,
      downloadUrl: map['download_url'] as String?,
      fileType: (map['file_type'] as String?) ?? 'pdf',
      fileSize: _parseInt(map['file_size']),
      source: RemoteBookSourceX.fromString(map['source'] as String?),
      publisher: map['publisher'] as String?,
      publishYear: _parseInt(map['publish_year']) == 0
          ? null
          : _parseInt(map['publish_year']),
      language: map['language'] as String?,
      subjects: _parseList(map['subjects']),
      isbn: map['isbn'] as String?,
      isAvailable: _toBool(map['is_available']),
    );
  }

  /// Converts this [RemoteBook] to a [Map] suitable for JSON serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'cover_url': coverUrl,
      'download_url': downloadUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'source': source.name,
      'publisher': publisher,
      'publish_year': publishYear,
      'language': language,
      'subjects': subjects,
      'isbn': isbn,
      'is_available': isAvailable,
    };
  }

  @override
  String toString() {
    return 'RemoteBook(id: $id, title: $title, author: $author, '
        'source: $source)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RemoteBook && other.id == id && other.source == source;
  }

  @override
  int get hashCode => Object.hash(id, source);

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value == '1' || value == 'true';
    return true;
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }
}
