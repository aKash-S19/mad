/// Quotes provider for the Libora reading ecosystem.
///
/// Manages all user-saved quotes with filtering by book, author, favorite
/// status, searching, and CRUD operations. Delegates persistence to
/// [DatabaseHelper].
library;

import 'package:flutter/foundation.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/quote_model.dart';

class QuotesProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Quote> _quotes = [];
  List<Quote> get quotes => _filteredQuotes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _filterByBook;
  String? get filterByBook => _filterByBook;

  String? _filterByAuthor;
  String? get filterByAuthor => _filterByAuthor;

  bool _filterFavorite = false;
  bool get filterFavorite => _filterFavorite;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Loads all quotes from the database.
  Future<void> loadQuotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _quotes = await _db.getRecentQuotes(limit: 500);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load quotes: $e';
      debugPrint('QuotesProvider: loadQuotes error: $e');
      notifyListeners();
    }
  }

  /// Adds a new quote.
  Future<void> addQuote(Quote quote) async {
    try {
      await _db.insertQuote(quote);
      _quotes.insert(0, quote);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add quote: $e';
      debugPrint('QuotesProvider: addQuote error: $e');
      notifyListeners();
    }
  }

  /// Updates an existing quote.
  Future<void> updateQuote(Quote quote) async {
    try {
      await _db.updateQuote(quote);
      _quotes =
          _quotes.map((q) => q.id == quote.id ? quote : q).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update quote: $e';
      debugPrint('QuotesProvider: updateQuote error: $e');
      notifyListeners();
    }
  }

  /// Deletes a quote by id.
  Future<void> deleteQuote(String id) async {
    try {
      await _db.deleteQuote(id);
      _quotes.removeWhere((q) => q.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete quote: $e';
      debugPrint('QuotesProvider: deleteQuote error: $e');
      notifyListeners();
    }
  }

  /// Toggles the favorite status of a quote.
  Future<void> toggleFavorite(String id) async {
    try {
      final quote = _quotes.where((q) => q.id == id).firstOrNull;
      if (quote == null) return;
      final updated =
          quote.copyWith(isFavorite: !quote.isFavorite);
      await _db.updateQuote(updated);
      _quotes = _quotes.map((q) => q.id == id ? updated : q).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to toggle favorite: $e';
      debugPrint('QuotesProvider: toggleFavorite error: $e');
      notifyListeners();
    }
  }

  /// Returns quotes for a specific book.
  Future<List<Quote>> getQuotesByBook(String bookId) async {
    try {
      return _db.getQuotesByBook(bookId);
    } catch (e) {
      _error = 'Failed to get quotes by book: $e';
      debugPrint('QuotesProvider: getQuotesByBook error: $e');
      notifyListeners();
      return [];
    }
  }

  /// Returns favorite quotes only.
  Future<List<Quote>> getFavoriteQuotes() async {
    try {
      return _db.getFavoriteQuotes();
    } catch (e) {
      _error = 'Failed to get favorite quotes: $e';
      debugPrint('QuotesProvider: getFavoriteQuotes error: $e');
      return [];
    }
  }

  /// Searches quotes by text content.
  Future<void> searchQuotes(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      await loadQuotes();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _quotes = await _db.searchQuotes(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Search failed: $e';
      debugPrint('QuotesProvider: searchQuotes error: $e');
      notifyListeners();
    }
  }

  /// Sets the book filter. Pass null to clear.
  void setBookFilter(String? bookId) {
    _filterByBook = bookId;
    notifyListeners();
  }

  /// Sets the author filter. Pass null to clear.
  void setAuthorFilter(String? author) {
    _filterByAuthor = author;
    notifyListeners();
  }

  /// Toggles the favorite-only filter.
  void toggleFavoriteFilter() {
    _filterFavorite = !_filterFavorite;
    notifyListeners();
  }

  /// Returns the filtered quote list based on current filters.
  List<Quote> get _filteredQuotes {
    List<Quote> result = List<Quote>.from(_quotes);

    if (_filterByBook != null) {
      result = result.where((q) => q.bookId == _filterByBook).toList();
    }

    if (_filterByAuthor != null) {
      result = result
          .where((q) =>
              q.author.toLowerCase() ==
              _filterByAuthor!.toLowerCase())
          .toList();
    }

    if (_filterFavorite) {
      result = result.where((q) => q.isFavorite).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((quote) =>
              quote.quoteText.toLowerCase().contains(q) ||
              (quote.personalThought?.toLowerCase().contains(q) ??
                  false) ||
              quote.author.toLowerCase().contains(q) ||
              quote.bookTitle.toLowerCase().contains(q))
          .toList();
    }

    return result;
  }

  /// Returns all unique authors from quotes.
  List<String> get uniqueAuthors {
    final authors = _quotes.map((q) => q.author).toSet().toList();
    authors.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return authors.where((a) => a.isNotEmpty).toList();
  }

  /// Returns the total count of quotes.
  int get totalCount => _quotes.length;

  /// Returns the count of favorite quotes.
  int get favoriteCount => _quotes.where((q) => q.isFavorite).length;

  /// Clears all filters.
  void clearFilters() {
    _filterByBook = null;
    _filterByAuthor = null;
    _filterFavorite = false;
    _searchQuery = '';
    notifyListeners();
  }

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Extension to add `firstOrNull` to Iterable.
extension IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
