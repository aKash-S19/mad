/// Chapter model for the Libora reading ecosystem.
///
/// Represents a single entry in a book's Table of Contents (TOC). Supports
/// nested structures via the [level] field (0 for top-level, 1 for sub-chapter,
/// etc.). The [href] references the content location within the book file.
library;

import 'package:flutter/foundation.dart';

@immutable
class Chapter {
  final String id;
  final String title;
  final String href;
  final int order;
  final int level;

  const Chapter({
    required this.id,
    required this.title,
    required this.href,
    this.order = 0,
    this.level = 0,
  });

  /// Creates a [Chapter] from a [Map] (typically from SQLite or an EPUB TOC).
  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] as String,
      title: map['title'] as String,
      href: (map['href'] as String?) ?? (map['content_ref'] as String?) ?? '',
      order: (map['order'] as int?) ?? 0,
      level: (map['level'] as int?) ?? 0,
    );
  }

  /// Converts this [Chapter] to a [Map] suitable for SQLite insertion.
  ///
  /// The href is stored under both `href` and `content_ref` keys for
  /// compatibility with varying column naming conventions.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'href': href,
      'content_ref': href,
      'order': order,
      'level': level,
    };
  }

  @override
  String toString() {
    return 'Chapter(id: $id, title: $title, order: $order, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chapter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
