/// Note model for the Libora reading ecosystem.
///
/// Represents a user-created note tied to a book, optionally linked to a
/// specific highlight. Notes capture the reader's thoughts about a passage.
library;

import 'package:flutter/foundation.dart';

@immutable
class Note {
  final String id;
  final String bookId;
  final String? highlightId;
  final String content;
  final String selectedText;
  final int page;
  final String location;
  final String? chapter;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.bookId,
    this.highlightId,
    this.content = '',
    this.selectedText = '',
    this.page = 0,
    this.location = '',
    this.chapter,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [Note] from a [Map] (typically from SQLite).
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      bookId: map['book_id'] as String,
      highlightId: map['highlight_id'] as String?,
      content: (map['content'] as String?) ?? '',
      selectedText: (map['selected_text'] as String?) ?? '',
      page: (map['page'] as int?) ?? 0,
      location: (map['location'] as String?) ?? '',
      chapter: map['chapter'] as String?,
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  /// Converts this [Note] to a [Map] suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'highlight_id': highlightId,
      'content': content,
      'selected_text': selectedText,
      'page': page,
      'location': location,
      'chapter': chapter,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [Note] with the given fields replaced.
  Note copyWith({
    String? id,
    String? bookId,
    String? highlightId,
    String? content,
    String? selectedText,
    int? page,
    String? location,
    String? chapter,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      highlightId: highlightId ?? this.highlightId,
      content: content ?? this.content,
      selectedText: selectedText ?? this.selectedText,
      page: page ?? this.page,
      location: location ?? this.location,
      chapter: chapter ?? this.chapter,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, bookId: $bookId, highlightId: $highlightId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note && other.id == id;
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
