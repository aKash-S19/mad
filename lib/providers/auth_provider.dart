/// Authentication provider for the Libora reading ecosystem.
///
/// Manages user authentication state via Firebase Auth and Firestore.
/// Supports email/password login, sign-up, Google Sign-In, guest mode,
/// and password reset. On successful login, creates/updates the user
/// document in the Firestore 'users' collection.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
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

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool get isLoggedIn => _currentUser != null && !_currentUser!.isGuest;
  bool get isGuest => _currentUser?.isGuest ?? false;

  /// Listen to auth state changes and sync with Firestore.
  void initAuthListener() {
    try {
      _auth?.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser != null) {
          await _syncUserFromFirestore(firebaseUser);
        } else if (_currentUser != null && !_currentUser!.isGuest) {
          _currentUser = null;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('AuthProvider: initAuthListener error: $e');
    }
  }

  /// Fetches or creates the user document in Firestore.
  Future<void> _syncUserFromFirestore(User firebaseUser) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final docRef = firestore.collection('users').doc(firebaseUser.uid);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final data = docSnap.data()!;
        _currentUser = UserModel.fromFirebase({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email ?? data['email'] ?? '',
          'display_name': data['display_name'] ??
              firebaseUser.displayName ??
              '',
          'username': data['username'] ?? '',
          'photo_url': data['photo_url'] ?? firebaseUser.photoURL,
          'bio': data['bio'] ?? '',
          'reading_goal': data['reading_goal'] ?? 12,
          'created_at': data['created_at'],
          'is_guest': false,
        });
      } else {
        // Create new user document
        final newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '',
          username: _generateUsername(firebaseUser.email ?? ''),
          photoUrl: firebaseUser.photoURL,
          readingGoal: 12,
          createdAt: DateTime.now(),
          isGuest: false,
        );
        await docRef.set(newUser.toFirestoreMap());
        _currentUser = newUser;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to sync user data: $e';
      debugPrint('AuthProvider: _syncUserFromFirestore error: $e');
      notifyListeners();
    }
  }

  /// Generates a username from an email address.
  String _generateUsername(String email) {
    final username = email.split('@').first;
    return username
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .toLowerCase();
  }

  /// Creates or updates the Firestore user document.
  Future<void> _createOrUpdateUserDocument(User firebaseUser,
      {String? displayName}) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final docRef = firestore.collection('users').doc(firebaseUser.uid);
      final docSnap = await docRef.get();

      final userData = {
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'display_name':
            displayName ?? firebaseUser.displayName ?? docSnap.data()?['display_name'] ?? '',
        'photo_url': firebaseUser.photoURL,
        'is_guest': false,
      };

      if (!docSnap.exists) {
        userData['username'] = _generateUsername(firebaseUser.email ?? '');
        userData['bio'] = '';
        userData['reading_goal'] = 12;
        userData['created_at'] = DateTime.now().toIso8601String();
        await docRef.set(userData);
      } else {
        await docRef.set(userData, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('AuthProvider: _createOrUpdateUserDocument error: $e');
    }
  }

  /// Sign in with email and password.
  Future<bool> loginWithEmail(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      _error = 'Firebase is not configured. Please use Continue as Guest.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _createOrUpdateUserDocument(credential.user!);
      await _syncUserFromFirestore(credential.user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _authErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sign up with email, password, and display name.
  Future<bool> signUpWithEmail(
      String email, String password, String displayName) async {
    final auth = _auth;
    if (auth == null) {
      _error = 'Firebase is not configured. Please use Continue as Guest.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name in Firebase Auth profile
      await credential.user!.updateDisplayName(displayName);

      // Create user document in Firestore
      await _createOrUpdateUserDocument(
        credential.user!,
        displayName: displayName,
      );

      await _syncUserFromFirestore(credential.user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _authErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google.
  Future<bool> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      _error = 'Firebase is not configured. Please use Continue as Guest.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      await _createOrUpdateUserDocument(userCredential.user!,
          displayName: googleUser.displayName);
      await _syncUserFromFirestore(userCredential.user!);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _authErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Google sign-in failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Continue as a guest user without authentication.
  Future<void> continueAsGuest() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = UserModel(
        uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Guest Reader',
        isGuest: true,
        createdAt: DateTime.now(),
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to continue as guest: $e';
      notifyListeners();
    }
  }

  /// Log out the current user.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }
      await _auth?.signOut();
      _currentUser = null;
    } catch (e) {
      _error = 'Logout failed: $e';
      debugPrint('AuthProvider: logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a password reset email.
  Future<bool> resetPassword(String email) async {
    final auth = _auth;
    if (auth == null) {
      _error = 'Firebase is not configured.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await auth.sendPasswordResetEmail(email: email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _authErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to send reset email: $e';
      notifyListeners();
      return false;
    }
  }

  /// Updates the current user's profile in Firestore.
  Future<void> updateProfile(UserModel updated) async {
    try {
      if (updated.isGuest) {
        _currentUser = updated;
        notifyListeners();
        return;
      }

      final firestore = _firestore;
      if (firestore != null) {
        final docRef = firestore.collection('users').doc(updated.uid);
        await docRef.set(updated.toFirestoreMap(), SetOptions(merge: true));
      }
      _currentUser = updated;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update profile: $e';
      debugPrint('AuthProvider: updateProfile error: $e');
      notifyListeners();
    }
  }

  /// Clears the current error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This operation is not enabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
