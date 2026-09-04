/// Highlight model for the Libora reading ecosystem.
///
/// Represents a highlighted text passage within a book. Highlights can be
/// color-coded and are linked to a specific page and chapter location.
library;

import 'package:flutter/foundation.dart';

@immutable
class Highlight {
  final String id;
  final String bookId;
  final String selectedText;
  final String color;
  final int page;
  final String location;
  final String? chapter;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Highlight({
    required this.id,
    required this.bookId,
    required this.selectedText,
    this.color = '#FFEB3B',
    this.page = 0,
    this.location = '',
    this.chapter,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [Highlight] from a [Map] (typically from SQLite).
  factory Highlight.fromMap(Map<String, dynamic> map) {
    return Highlight(
      id: map['id'] as String,
      bookId: map['book_id'] as String,
      selectedText: map['selected_text'] as String,
      color: (map['color'] as String?) ?? '#FFEB3B',
      page: (map['page'] as int?) ?? 0,
      location: (map['location'] as String?) ?? '',
      chapter: map['chapter'] as String?,
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  /// Converts this [Highlight] to a [Map] suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'selected_text': selectedText,
      'color': color,
      'page': page,
      'location': location,
      'chapter': chapter,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [Highlight] with the given fields replaced.
  Highlight copyWith({
    String? id,
    String? bookId,
    String? selectedText,
    String? color,
    int? page,
    String? location,
    String? chapter,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Highlight(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      selectedText: selectedText ?? this.selectedText,
      color: color ?? this.color,
      page: page ?? this.page,
      location: location ?? this.location,
      chapter: chapter ?? this.chapter,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Highlight(id: $id, bookId: $bookId, page: $page, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Highlight && other.id == id;
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
