/// Notes provider for the Libora reading ecosystem.
///
/// Manages all user notes with filtering by book, searching, and CRUD
/// operations. Delegates persistence to [DatabaseHelper].
library;

import 'package:flutter/foundation.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/note_model.dart';

class NotesProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Note> _notes = [];
  List<Note> get notes => _filteredNotes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _filterByBook;
  String? get filterByBook => _filterByBook;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Loads all notes from the database.
  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _db.getRecentNotes(limit: 500);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load notes: $e';
      debugPrint('NotesProvider: loadNotes error: $e');
      notifyListeners();
    }
  }

  /// Adds a new note.
  Future<void> addNote(Note note) async {
    try {
      await _db.insertNote(note);
      _notes.insert(0, note);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add note: $e';
      debugPrint('NotesProvider: addNote error: $e');
      notifyListeners();
    }
  }

  /// Updates an existing note.
  Future<void> updateNote(Note note) async {
    try {
      final updated = note.copyWith(updatedAt: DateTime.now());
      await _db.updateNote(updated);
      _notes =
          _notes.map((n) => n.id == updated.id ? updated : n).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update note: $e';
      debugPrint('NotesProvider: updateNote error: $e');
      notifyListeners();
    }
  }

  /// Deletes a note by id.
  Future<void> deleteNote(String id) async {
    try {
      await _db.deleteNote(id);
      _notes.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete note: $e';
      debugPrint('NotesProvider: deleteNote error: $e');
      notifyListeners();
    }
  }

  /// Returns notes for a specific book.
  Future<List<Note>> getNotesByBook(String bookId) async {
    try {
      return _db.getNotesByBook(bookId);
    } catch (e) {
      _error = 'Failed to get notes by book: $e';
      debugPrint('NotesProvider: getNotesByBook error: $e');
      notifyListeners();
      return [];
    }
  }

  /// Searches notes by content or selected text.
  Future<void> searchNotes(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      await loadNotes();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _notes = await _db.searchNotes(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Search failed: $e';
      debugPrint('NotesProvider: searchNotes error: $e');
      notifyListeners();
    }
  }

  /// Sets the book filter. Pass null to clear.
  void setBookFilter(String? bookId) {
    _filterByBook = bookId;
    notifyListeners();
  }

  /// Returns the filtered note list based on current filters.
  List<Note> get _filteredNotes {
    List<Note> result = List<Note>.from(_notes);

    if (_filterByBook != null) {
      result = result.where((n) => n.bookId == _filterByBook).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((note) =>
              note.content.toLowerCase().contains(q) ||
              note.selectedText.toLowerCase().contains(q))
          .toList();
    }

    return result;
  }

  /// Returns notes that are linked to a highlight.
  List<Note> get notesWithHighlights {
    return _notes.where((n) => n.highlightId != null).toList();
  }

  /// Returns the total count of notes.
  int get totalCount => _notes.length;

  /// Clears all filters.
  void clearFilters() {
    _filterByBook = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
