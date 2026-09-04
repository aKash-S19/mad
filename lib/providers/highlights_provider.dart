/// Highlights provider for the Libora reading ecosystem.
///
/// Manages all highlights across the library with filtering by book and
/// color, searching, and CRUD operations. Delegates persistence to
/// [DatabaseHelper].
library;

import 'package:flutter/foundation.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/highlight_model.dart';

class HighlightsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Highlight> _highlights = [];
  List<Highlight> get highlights => _filteredHighlights;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _filterByBook;
  String? get filterByBook => _filterByBook;

  String? _filterByColor;
  String? get filterByColor => _filterByColor;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Loads all highlights from the database.
  Future<void> loadHighlights() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _highlights = await _db.getRecentHighlights(limit: 500);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load highlights: $e';
      debugPrint('HighlightsProvider: loadHighlights error: $e');
      notifyListeners();
    }
  }

  /// Adds a new highlight.
  Future<void> addHighlight(Highlight highlight) async {
    try {
      await _db.insertHighlight(highlight);
      _highlights.insert(0, highlight);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add highlight: $e';
      debugPrint('HighlightsProvider: addHighlight error: $e');
      notifyListeners();
    }
  }

  /// Updates an existing highlight.
  Future<void> updateHighlight(Highlight highlight) async {
    try {
      final updated = highlight.copyWith(updatedAt: DateTime.now());
      await _db.updateHighlight(updated);
      _highlights = _highlights
          .map((h) => h.id == updated.id ? updated : h)
          .toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update highlight: $e';
      debugPrint('HighlightsProvider: updateHighlight error: $e');
      notifyListeners();
    }
  }

  /// Deletes a highlight by id.
  Future<void> deleteHighlight(String id) async {
    try {
      await _db.deleteHighlight(id);
      _highlights.removeWhere((h) => h.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete highlight: $e';
      debugPrint('HighlightsProvider: deleteHighlight error: $e');
      notifyListeners();
    }
  }

  /// Returns highlights for a specific book.
  Future<List<Highlight>> getHighlightsByBook(String bookId) async {
    try {
      return _db.getHighlightsByBook(bookId);
    } catch (e) {
      _error = 'Failed to get highlights by book: $e';
      debugPrint('HighlightsProvider: getHighlightsByBook error: $e');
      notifyListeners();
      return [];
    }
  }

  /// Returns recent highlights across all books.
  Future<List<Highlight>> getRecentHighlights({int limit = 20}) async {
    try {
      return _db.getRecentHighlights(limit: limit);
    } catch (e) {
      _error = 'Failed to get recent highlights: $e';
      debugPrint('HighlightsProvider: getRecentHighlights error: $e');
      return [];
    }
  }

  /// Searches highlights by text content.
  Future<void> searchHighlights(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      await loadHighlights();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _highlights = await _db.searchHighlights(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Search failed: $e';
      debugPrint('HighlightsProvider: searchHighlights error: $e');
      notifyListeners();
    }
  }

  /// Sets the book filter. Pass null to clear.
  void setBookFilter(String? bookId) {
    _filterByBook = bookId;
    notifyListeners();
  }

  /// Sets the color filter. Pass null to clear.
  void setColorFilter(String? color) {
    _filterByColor = color;
    notifyListeners();
  }

  /// Returns the filtered highlight list based on current filters.
  List<Highlight> get _filteredHighlights {
    List<Highlight> result = List<Highlight>.from(_highlights);

    if (_filterByBook != null) {
      result =
          result.where((h) => h.bookId == _filterByBook).toList();
    }

    if (_filterByColor != null) {
      result =
          result.where((h) => h.color == _filterByColor).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((h) => h.selectedText.toLowerCase().contains(q))
          .toList();
    }

    return result;
  }

  /// Returns highlights grouped by color.
  Map<String, List<Highlight>> get highlightsByColor {
    final map = <String, List<Highlight>>{};
    for (final h in _highlights) {
      map.putIfAbsent(h.color, () => []).add(h);
    }
    return map;
  }

  /// Returns the count of highlights.
  int get totalCount => _highlights.length;

  /// Clears all filters.
  void clearFilters() {
    _filterByBook = null;
    _filterByColor = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
