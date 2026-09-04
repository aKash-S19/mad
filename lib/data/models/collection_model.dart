/// Collection model for the Libora reading ecosystem.
///
/// Represents a user-created collection (shelf) that groups books together.
/// Collections are visually identified by a hex color string and maintain
/// an ordered list of book IDs.
library;

import 'package:flutter/foundation.dart';

@immutable
class Collection {
  final String id;
  final String name;
  final String description;
  final String color;
  final List<String> bookIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Collection({
    required this.id,
    required this.name,
    this.description = '',
    this.color = '#1976D2',
    this.bookIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [Collection] from a [Map] (typically from SQLite).
  ///
  /// The [bookIds] are stored as a comma-separated string in the database
  /// and parsed back into a [List<String>].
  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      color: (map['color'] as String?) ?? '#1976D2',
      bookIds: _parseList(map['book_ids']),
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  /// Converts this [Collection] to a [Map] suitable for SQLite insertion.
  ///
  /// The [bookIds] list is serialized as a comma-separated string. The
  /// junction table (`collection_books`) is maintained separately by the
  /// database helper for referential integrity.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'book_ids': bookIds.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [Collection] with the given fields replaced.
  Collection copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    List<String>? bookIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      bookIds: bookIds ?? this.bookIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Collection(id: $id, name: $name, bookIds: ${bookIds.length} books)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Collection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
