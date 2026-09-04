/// User model for the Libora reading ecosystem.
///
/// Represents an authenticated user of the app, either a signed-in Firebase
/// user or a guest. Stores profile information and the annual reading goal.
library;

import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String? photoUrl;
  final String bio;
  final int readingGoal;
  final DateTime createdAt;
  final bool isGuest;

  const UserModel({
    required this.uid,
    this.email = '',
    this.displayName = '',
    this.username = '',
    this.photoUrl,
    this.bio = '',
    this.readingGoal = 12,
    required this.createdAt,
    this.isGuest = false,
  });

  /// Creates a [UserModel] from a [Map] (typically from SQLite or Firestore).
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: (map['email'] as String?) ?? '',
      displayName: (map['display_name'] as String?) ?? '',
      username: (map['username'] as String?) ?? '',
      photoUrl: map['photo_url'] as String?,
      bio: (map['bio'] as String?) ?? '',
      readingGoal: (map['reading_goal'] as int?) ?? 12,
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      isGuest: _toBool(map['is_guest']),
    );
  }

  /// Converts this [UserModel] to a [Map] suitable for SQLite or Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'username': username,
      'photo_url': photoUrl,
      'bio': bio,
      'reading_goal': readingGoal,
      'created_at': createdAt.toIso8601String(),
      'is_guest': isGuest ? 1 : 0,
    };
  }

  /// Converts this [UserModel] to a [Map] suitable for Firestore, where
  /// booleans are stored as actual booleans (not integers) and timestamps
  /// as [FieldValue.serverTimestamp] when appropriate.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'username': username,
      'photo_url': photoUrl,
      'bio': bio,
      'reading_goal': readingGoal,
      'created_at': createdAt.toIso8601String(),
      'is_guest': isGuest,
    };
  }

  /// Creates a [UserModel] from a Firebase [User] Map (as returned by
  /// `firebase_auth` user profile data or a Firestore document snapshot).
  ///
  /// The [firebaseData] map should contain standard Firebase user fields
  /// such as `uid`, `email`, `displayName`, `photoURL`, etc.
  factory UserModel.fromFirebase(Map<String, dynamic> firebaseData) {
    return UserModel(
      uid: firebaseData['uid'] as String,
      email: (firebaseData['email'] as String?) ?? '',
      displayName:
          (firebaseData['display_name'] as String?) ??
              (firebaseData['displayName'] as String?) ??
              '',
      username: (firebaseData['username'] as String?) ?? '',
      photoUrl: (firebaseData['photo_url'] as String?) ??
          (firebaseData['photoURL'] as String?),
      bio: (firebaseData['bio'] as String?) ?? '',
      readingGoal: (firebaseData['reading_goal'] as int?) ?? 12,
      createdAt: _parseDate(firebaseData['created_at']) ??
          _parseDate(firebaseData['createdAt']) ??
          DateTime.now(),
      isGuest: firebaseData['is_guest'] as bool? ?? false,
    );
  }

  /// Creates a copy of this [UserModel] with the given fields replaced.
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    String? photoUrl,
    String? bio,
    int? readingGoal,
    DateTime? createdAt,
    bool? isGuest,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      readingGoal: readingGoal ?? this.readingGoal,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, displayName: $displayName, '
        'isGuest: $isGuest, readingGoal: $readingGoal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

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
    // Handle Firestore Timestamp-like objects
    if (value is Map && value.containsKey('_seconds')) {
      final seconds = value['_seconds'] as int;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return null;
  }
}
