/// Profile provider for the Libora reading ecosystem.
///
/// Manages user profile data, friends, reviews, favorite books, saved
/// quotes, and collections summary. Uses Firebase Auth and Firestore for
/// user data and social features.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/book_review_model.dart';
import 'package:libora/data/models/collection_model.dart';
import 'package:libora/data/models/quote_model.dart';
import 'package:libora/data/models/user_model.dart';

class ProfileProvider extends ChangeNotifier {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  final DatabaseHelper _db = DatabaseHelper();

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  List<Book> _favoriteBooks = [];
  List<Book> get favoriteBooks => _favoriteBooks;

  List<Quote> _savedQuotes = [];
  List<Quote> get savedQuotes => _savedQuotes;

  List<Collection> _userCollections = [];
  List<Collection> get userCollections => _userCollections;

  List<UserModel> _friends = [];
  List<UserModel> get friends => _friends;

  List<BookReview> _reviews = [];
  List<BookReview> get reviews => _reviews;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Loads the full profile: user data, favorites, saved quotes,
  /// collections, friends, and reviews.
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load user data from Firestore if logged in
      final firebaseUser = _auth?.currentUser;
      final firestore = _firestore;
      if (firebaseUser != null && firestore != null) {
        final docSnap = await firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        if (docSnap.exists) {
          _userModel = UserModel.fromFirebase({
            'uid': firebaseUser.uid,
            ...docSnap.data()!,
          });
        }
      }

      // Load local data in parallel
      final results = await Future.wait([
        _db.getFavoriteBooks(),
        _db.getRecentQuotes(limit: 50),
        _db.getAllCollections(),
        _db.getRecentQuotes(limit: 100),
      ]);

      _favoriteBooks = results[0] as List<Book>;
      _savedQuotes = results[1] as List<Quote>;
      _userCollections = results[2] as List<Collection>;

      // Load friends from Firestore
      await _loadFriends();

      // Load reviews from Firestore
      await _loadReviews();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load profile: $e';
      debugPrint('ProfileProvider: loadProfile error: $e');
      notifyListeners();
    }
  }

  /// Updates the user's profile in Firestore.
  Future<void> updateProfile(UserModel updated) async {
    _isLoading = true;
    notifyListeners();

    try {
      final firestore = _firestore;
      if (!updated.isGuest && firestore != null) {
        await firestore
            .collection('users')
            .doc(updated.uid)
            .set(updated.toFirestoreMap(), SetOptions(merge: true));
      }
      _userModel = updated;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to update profile: $e';
      debugPrint('ProfileProvider: updateProfile error: $e');
      notifyListeners();
    }
  }

  /// Searches for a user by username.
  Future<UserModel?> searchUserByUsername(String username) async {
    final firestore = _firestore;
    if (firestore == null) return null;
    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return UserModel.fromFirebase({
          'uid': querySnapshot.docs.first.id,
          ...data,
        });
      }
      return null;
    } catch (e) {
      _error = 'Failed to search user: $e';
      debugPrint('ProfileProvider: searchUserByUsername error: $e');
      notifyListeners();
      return null;
    }
  }

  /// Adds a friend by username.
  Future<bool> addFriend(String username) async {
    final firestore = _firestore;
    final currentUid = _auth?.currentUser?.uid;
    if (firestore == null || currentUid == null) {
      _error = 'Profile sync is available when logged in.';
      notifyListeners();
      return false;
    }

    try {
      final friend = await searchUserByUsername(username);
      if (friend == null) {
        _error = 'User not found';
        notifyListeners();
        return false;
      }

      // Add to friends subcollection
      await firestore
          .collection('users')
          .doc(currentUid)
          .collection('friends')
          .doc(friend.uid)
          .set({
        'uid': friend.uid,
        'username': friend.username,
        'display_name': friend.displayName,
        'added_at': DateTime.now().toIso8601String(),
      });

      _friends.add(friend);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add friend: $e';
      debugPrint('ProfileProvider: addFriend error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Loads the user's friends from Firestore.
  Future<List<UserModel>> getFriends() async {
    await _loadFriends();
    return _friends;
  }

  Future<void> _loadFriends() async {
    final firestore = _firestore;
    final currentUid = _auth?.currentUser?.uid;
    if (firestore == null || currentUid == null) {
      _friends = [];
      return;
    }

    try {
      final snapshot = await firestore
          .collection('users')
          .doc(currentUid)
          .collection('friends')
          .get();

      _friends = snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          uid: data['uid'] as String? ?? doc.id,
          displayName: data['display_name'] as String? ?? '',
          username: data['username'] as String? ?? '',
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('ProfileProvider: _loadFriends error: $e');
      _friends = [];
    }
  }

  /// Generates a shareable profile summary text.
  String shareProfile() {
    if (_userModel == null) return '';
    final name = _userModel!.displayName.isNotEmpty
        ? _userModel!.displayName
        : 'Reader';
    final buffer = StringBuffer();
    buffer.writeln('Check out $name on Libora!');
    buffer.writeln('');
    buffer.writeln(
        'Books read: ${_favoriteBooks.length} favorites');
    buffer.writeln(
        'Quotes saved: ${_savedQuotes.length}');
    buffer.writeln(
        'Collections: ${_userCollections.length}');
    buffer.writeln('Reading goal: ${_userModel!.readingGoal} books/year');
    buffer.writeln('');
    buffer.writeln('Join me on Libora - your personal reading ecosystem.');
    return buffer.toString();
  }

  /// Adds a book review to Firestore.
  Future<bool> addReview(BookReview review) async {
    final firestore = _firestore;
    final currentUid = _auth?.currentUser?.uid;
    if (firestore == null || currentUid == null) {
      _reviews.insert(0, review);
      notifyListeners();
      return true;
    }

    try {
      // Save to Firestore
      await firestore
          .collection('reviews')
          .doc(review.id)
          .set({
        ...review.toMap(),
        'user_id': currentUid,
      });

      _reviews.insert(0, review);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add review: $e';
      debugPrint('ProfileProvider: addReview error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Returns reviews for a specific book.
  Future<List<BookReview>> getReviewsForBook(String bookId) async {
    final firestore = _firestore;
    if (firestore == null) {
      return _reviews.where((r) => r.bookId == bookId).toList();
    }
    try {
      final snapshot = await firestore
          .collection('reviews')
          .where('book_id', isEqualTo: bookId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BookReview.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('ProfileProvider: getReviewsForBook error: $e');
      return _reviews.where((r) => r.bookId == bookId).toList();
    }
  }

  Future<void> _loadReviews() async {
    final firestore = _firestore;
    final currentUid = _auth?.currentUser?.uid;
    if (firestore == null || currentUid == null) {
      _reviews = [];
      return;
    }

    try {
      final snapshot = await firestore
          .collection('reviews')
          .where('user_id', isEqualTo: currentUid)
          .orderBy('created_at', descending: true)
          .get();

      _reviews = snapshot.docs.map((doc) {
        final data = doc.data();
        return BookReview.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('ProfileProvider: _loadReviews error: $e');
      _reviews = [];
    }
  }

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
