/// Quote model for the Libora reading ecosystem.
///
/// Represents an excerpted passage from a book that the user has saved as
/// a standalone quote. Quotes include bibliographic context and an optional
/// personal thought from the reader.
library;

import 'package:flutter/foundation.dart';

@immutable
class Quote {
  final String id;
  final String bookId;
  final String quoteText;
  final String bookTitle;
  final String author;
  final int page;
  final String location;
  final String? chapter;
  final String? personalThought;
  final bool isFavorite;
  final DateTime createdAt;

  const Quote({
    required this.id,
    required this.bookId,
    required this.quoteText,
    this.bookTitle = '',
    this.author = '',
    this.page = 0,
    this.location = '',
    this.chapter,
    this.personalThought,
    this.isFavorite = false,
    required this.createdAt,
  });

  /// Creates a [Quote] from a [Map] (typically from SQLite).
  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as String,
      bookId: map['book_id'] as String,
      quoteText: map['quote_text'] as String,
      bookTitle: (map['book_title'] as String?) ?? '',
      author: (map['author'] as String?) ?? '',
      page: (map['page'] as int?) ?? 0,
      location: (map['location'] as String?) ?? '',
      chapter: map['chapter'] as String?,
      personalThought: map['personal_thought'] as String?,
      isFavorite: _toBool(map['is_favorite']),
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
    );
  }

  /// Converts this [Quote] to a [Map] suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'quote_text': quoteText,
      'book_title': bookTitle,
      'author': author,
      'page': page,
      'location': location,
      'chapter': chapter,
      'personal_thought': personalThought,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [Quote] with the given fields replaced.
  Quote copyWith({
    String? id,
    String? bookId,
    String? quoteText,
    String? bookTitle,
    String? author,
    int? page,
    String? location,
    String? chapter,
    String? personalThought,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Quote(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      quoteText: quoteText ?? this.quoteText,
      bookTitle: bookTitle ?? this.bookTitle,
      author: author ?? this.author,
      page: page ?? this.page,
      location: location ?? this.location,
      chapter: chapter ?? this.chapter,
      personalThought: personalThought ?? this.personalThought,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Quote(id: $id, bookId: $bookId, isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Quote && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value == '1' || value == 'true';
    return false;
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
