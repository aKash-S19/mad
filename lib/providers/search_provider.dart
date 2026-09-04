/// Global search provider for the Libora reading ecosystem.
///
/// Performs a unified search across all content types: books, highlights,
/// quotes, notes, and collections. Returns grouped results for display
/// in a unified search interface.
library;

import 'package:flutter/foundation.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/collection_model.dart';
import 'package:libora/data/models/highlight_model.dart';
import 'package:libora/data/models/note_model.dart';
import 'package:libora/data/models/quote_model.dart';

/// Grouped search results from all content types.
class GlobalSearchResult {
  final List<Book> books;
  final List<Highlight> highlights;
  final List<Quote> quotes;
  final List<Note> notes;
  final List<Collection> collections;

  const GlobalSearchResult({
    this.books = const [],
    this.highlights = const [],
    this.quotes = const [],
    this.notes = const [],
    this.collections = const [],
  });

  bool get isEmpty =>
      books.isEmpty &&
      highlights.isEmpty &&
      quotes.isEmpty &&
      notes.isEmpty &&
      collections.isEmpty;

  int get totalCount =>
      books.length +
      highlights.length +
      quotes.length +
      notes.length +
      collections.length;
}

class SearchProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  String _query = '';
  String get query => _query;

  List<Book> _books = [];
  List<Book> get books => _books;

  List<Highlight> _highlights = [];
  List<Highlight> get highlights => _highlights;

  List<Quote> _quotes = [];
  List<Quote> get quotes => _quotes;

  List<Note> _notes = [];
  List<Note> get notes => _notes;

  List<Collection> _collections = [];
  List<Collection> get collections => _collections;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasSearched = false;
  bool get hasSearched => _hasSearched;

  /// Performs a global search across all content types.
  Future<GlobalSearchResult> globalSearch(String query) async {
    _query = query;
    _hasSearched = true;

    if (query.trim().isEmpty) {
      _books = [];
      _highlights = [];
      _quotes = [];
      _notes = [];
      _collections = [];
      notifyListeners();
      return const GlobalSearchResult();
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Search all content types in parallel
      final results = await Future.wait([
        _db.searchBooks(query),
        _db.searchHighlights(query),
        _db.searchQuotes(query),
        _db.searchNotes(query),
        _db.searchCollections(query),
      ]);

      _books = results[0] as List<Book>;
      _highlights = results[1] as List<Highlight>;
      _quotes = results[2] as List<Quote>;
      _notes = results[3] as List<Note>;
      _collections = results[4] as List<Collection>;

      _isLoading = false;
      notifyListeners();

      return GlobalSearchResult(
        books: _books,
        highlights: _highlights,
        quotes: _quotes,
        notes: _notes,
        collections: _collections,
      );
    } catch (e) {
      _isLoading = false;
      debugPrint('SearchProvider: globalSearch error: $e');
      notifyListeners();
      return const GlobalSearchResult();
    }
  }

  /// Returns the grouped result from the last search.
  GlobalSearchResult get currentResults => GlobalSearchResult(
        books: _books,
        highlights: _highlights,
        quotes: _quotes,
        notes: _notes,
        collections: _collections,
      );

  /// Clears all search results.
  void clearSearch() {
    _query = '';
    _books = [];
    _highlights = [];
    _quotes = [];
    _notes = [];
    _collections = [];
    _hasSearched = false;
    notifyListeners();
  }
}
