/// Collections provider for the Libora reading ecosystem.
///
/// Manages user-created collections (shelves): create, update, delete,
/// add/remove books, and query collections for a given book. Delegates
/// persistence to [DatabaseHelper].
library;

import 'package:flutter/foundation.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/collection_model.dart';
import 'package:uuid/uuid.dart';

class CollectionsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  List<Collection> _collections = [];
  List<Collection> get collections => _collections;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Loads all collections from the database.
  Future<void> loadCollections() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _collections = await _db.getAllCollections();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load collections: $e';
      debugPrint('CollectionsProvider: loadCollections error: $e');
      notifyListeners();
    }
  }

  /// Creates a new collection.
  Future<Collection?> createCollection(
    String name, {
    String description = '',
    String color = '#1976D2',
  }) async {
    try {
      final collection = Collection(
        id: _uuid.v4(),
        name: name,
        description: description,
        color: color,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _db.insertCollection(collection);
      _collections.insert(0, collection);
      notifyListeners();
      return collection;
    } catch (e) {
      _error = 'Failed to create collection: $e';
      debugPrint('CollectionsProvider: createCollection error: $e');
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing collection.
  Future<void> updateCollection(Collection collection) async {
    try {
      final updated =
          collection.copyWith(updatedAt: DateTime.now());
      await _db.updateCollection(updated);
      _collections = _collections
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update collection: $e';
      debugPrint('CollectionsProvider: updateCollection error: $e');
      notifyListeners();
    }
  }

  /// Deletes a collection by id.
  Future<void> deleteCollection(String id) async {
    try {
      await _db.deleteCollection(id);
      _collections.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete collection: $e';
      debugPrint('CollectionsProvider: deleteCollection error: $e');
      notifyListeners();
    }
  }

  /// Adds a book to a collection.
  Future<void> addBookToCollection(
      String collectionId, String bookId) async {
    try {
      await _db.addBookToCollection(collectionId, bookId);

      // Update in-memory list
      _collections = _collections.map((c) {
        if (c.id == collectionId && !c.bookIds.contains(bookId)) {
          return c.copyWith(
            bookIds: [...c.bookIds, bookId],
            updatedAt: DateTime.now(),
          );
        }
        return c;
      }).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add book to collection: $e';
      debugPrint(
          'CollectionsProvider: addBookToCollection error: $e');
      notifyListeners();
    }
  }

  /// Removes a book from a collection.
  Future<void> removeBookFromCollection(
      String collectionId, String bookId) async {
    try {
      await _db.removeBookFromCollection(collectionId, bookId);

      // Update in-memory list
      _collections = _collections.map((c) {
        if (c.id == collectionId) {
          return c.copyWith(
            bookIds: c.bookIds.where((id) => id != bookId).toList(),
            updatedAt: DateTime.now(),
          );
        }
        return c;
      }).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove book from collection: $e';
      debugPrint(
          'CollectionsProvider: removeBookFromCollection error: $e');
      notifyListeners();
    }
  }

  /// Returns all collections that contain the given book.
  List<Collection> getCollectionsForBook(String bookId) {
    return _collections
        .where((c) => c.bookIds.contains(bookId))
        .toList();
  }

  /// Returns a collection by id.
  Future<Collection?> getCollectionById(String id) async {
    try {
      final cached =
          _collections.where((c) => c.id == id).toList();
      if (cached.isNotEmpty) return cached.first;
      return await _db.getCollectionById(id);
    } catch (e) {
      _error = 'Failed to get collection: $e';
      debugPrint('CollectionsProvider: getCollectionById error: $e');
      return null;
    }
  }

  /// Returns the total count of collections.
  int get totalCount => _collections.length;

  /// Returns the total number of books across all collections.
  int get totalBooks =>
      _collections.fold(0, (sum, c) => sum + c.bookIds.length);

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
