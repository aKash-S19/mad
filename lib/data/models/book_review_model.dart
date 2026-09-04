/// Book review model for the Libora reading ecosystem.
///
/// Represents a user's review and rating for a book. Reviews include a
/// 1–5 star rating, optional text, and are attributed to a specific user.
library;

import 'package:flutter/foundation.dart';

@immutable
class BookReview {
  final String id;
  final String bookId;
  final String bookTitle;
  final String bookAuthor;
  final String userId;
  final String username;
  final int rating;
  final String reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookReview({
    required this.id,
    required this.bookId,
    this.bookTitle = '',
    this.bookAuthor = '',
    required this.userId,
    this.username = '',
    this.rating = 0,
    this.reviewText = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [BookReview] from a [Map] (typically from SQLite).
  factory BookReview.fromMap(Map<String, dynamic> map) {
    return BookReview(
      id: map['id'] as String,
      bookId: map['book_id'] as String,
      bookTitle: (map['book_title'] as String?) ?? '',
      bookAuthor: (map['book_author'] as String?) ?? '',
      userId: map['user_id'] as String,
      username: (map['username'] as String?) ?? '',
      rating: (map['rating'] as int?) ?? 0,
      reviewText: (map['review_text'] as String?) ?? '',
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  /// Converts this [BookReview] to a [Map] suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'book_title': bookTitle,
      'book_author': bookAuthor,
      'user_id': userId,
      'username': username,
      'rating': rating,
      'review_text': reviewText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [BookReview] with the given fields replaced.
  BookReview copyWith({
    String? id,
    String? bookId,
    String? bookTitle,
    String? bookAuthor,
    String? userId,
    String? username,
    int? rating,
    String? reviewText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookReview(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BookReview(id: $id, bookId: $bookId, userId: $userId, '
        'rating: $rating/5)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookReview && other.id == id;
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
