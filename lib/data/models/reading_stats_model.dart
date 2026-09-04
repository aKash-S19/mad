/// Reading statistics model for the Libora reading ecosystem.
///
/// Tracks per-session reading metrics for a book: pages read, time spent,
/// and the current page reached during the session. Each session is identified
/// by a unique [sessionId] and tied to a specific [date].
library;

import 'package:flutter/foundation.dart';

@immutable
class ReadingStats {
  final String id;
  final String bookId;
  final DateTime date;
  final int pagesRead;
  final int readingTimeSeconds;
  final int currentPage;
  final String sessionId;

  const ReadingStats({
    required this.id,
    required this.bookId,
    required this.date,
    this.pagesRead = 0,
    this.readingTimeSeconds = 0,
    this.currentPage = 0,
    required this.sessionId,
  });

  /// Creates a [ReadingStats] from a [Map] (typically from SQLite).
  factory ReadingStats.fromMap(Map<String, dynamic> map) {
    return ReadingStats(
      id: map['id'] as String,
      bookId: map['book_id'] as String,
      date: _parseDate(map['date']) ?? DateTime.now(),
      pagesRead: (map['pages_read'] as int?) ?? 0,
      readingTimeSeconds: (map['reading_time_seconds'] as int?) ?? 0,
      currentPage: (map['current_page'] as int?) ?? 0,
      sessionId: map['session_id'] as String,
    );
  }

  /// Converts this [ReadingStats] to a [Map] suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'date': date.toIso8601String(),
      'pages_read': pagesRead,
      'reading_time_seconds': readingTimeSeconds,
      'current_page': currentPage,
      'session_id': sessionId,
    };
  }

  /// Creates a copy of this [ReadingStats] with the given fields replaced.
  ReadingStats copyWith({
    String? id,
    String? bookId,
    DateTime? date,
    int? pagesRead,
    int? readingTimeSeconds,
    int? currentPage,
    String? sessionId,
  }) {
    return ReadingStats(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      date: date ?? this.date,
      pagesRead: pagesRead ?? this.pagesRead,
      readingTimeSeconds:
          readingTimeSeconds ?? this.readingTimeSeconds,
      currentPage: currentPage ?? this.currentPage,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  String toString() {
    return 'ReadingStats(id: $id, bookId: $bookId, pagesRead: $pagesRead, '
        'readingTime: ${readingTimeSeconds}s)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingStats && other.id == id;
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
