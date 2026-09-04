/// Bookmark model for the Libora reading ecosystem.
///
/// Represents a saved position within a book that the user can return to.
/// Bookmarks pin to a specific page and chapter location, and can be
/// given an optional user-defined title.
library;

import 'package:flutter/foundation.dart';

@immutable
class Bookmark {
  final String id;
  final String bookId;
  final int page;
  final String location;
  final String? chapter;
  final String? title;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.bookId,
    this.page = 0,
    this.location = '',
    this.chapter,
    this.title,
    required this.createdAt,
  });

  /// Creates a [Bookmark] from a [Map] (typically from SQLite).
  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as String,
      bookId: map['book_id'] as String,
      page: (map['page'] as int?) ?? 0,
      location: (map['location'] as String?) ?? '',
      chapter: map['chapter'] as String?,
      title: map['title'] as String?,
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
    );
  }

  /// Converts this [Bookmark] to a [Map] suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'page': page,
      'location': location,
      'chapter': chapter,
      'title': title,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [Bookmark] with the given fields replaced.
  Bookmark copyWith({
    String? id,
    String? bookId,
    int? page,
    String? location,
    String? chapter,
    String? title,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      page: page ?? this.page,
      location: location ?? this.location,
      chapter: chapter ?? this.chapter,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Bookmark(id: $id, bookId: $bookId, page: $page, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bookmark && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
