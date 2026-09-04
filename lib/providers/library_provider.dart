/// Library provider for the Libora reading ecosystem.
///
/// Manages the user's book collection: CRUD operations, import, search,
/// filter, sort, and reading progress tracking. Delegates persistence to
/// [DatabaseHelper].
library;

import 'package:flutter/foundation.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/remote_book_model.dart';
import 'package:libora/services/book_import_service.dart';
import 'package:uuid/uuid.dart';

/// Sort criteria for the library.
enum LibrarySortBy { title, author, date, progress }

/// Filter status for the library.
enum LibraryFilterStatus {
  all,
  wantToRead,
  currentlyReading,
  completed,
  favorite
}

/// Library view mode.
enum LibraryViewMode { grid, list }

class LibraryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  List<Book> _books = [];
  List<Book> get books => _books;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  LibrarySortBy _sortBy = LibrarySortBy.date;
  LibrarySortBy get sortBy => _sortBy;

  LibraryFilterStatus _filterStatus = LibraryFilterStatus.all;
  LibraryFilterStatus get filterStatus => _filterStatus;

  LibraryViewMode _viewMode = LibraryViewMode.grid;
  LibraryViewMode get viewMode => _viewMode;

  /// Loads all books from the database and applies current sort/filter.
  Future<void> loadBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _books = await _db.getAllBooks();
      _applyFilters();
    } catch (e) {
      _error = 'Failed to load books: $e';
      debugPrint('LibraryProvider: loadBooks error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a book to the library.
  Future<void> addBook(Book book) async {
    try {
      await _db.insertBook(book);
      if (!_books.any((b) => b.id == book.id)) {
        _books.insert(0, book);
      } else {
        _books = _books.map((b) => b.id == book.id ? book : b).toList();
      }
      _applyFilters();
    } catch (e) {
      _error = 'Failed to add book: $e';
      debugPrint('LibraryProvider: addBook error: $e');
      notifyListeners();
    }
  }

  /// Updates an existing book in the library.
  Future<void> updateBook(Book book) async {
    try {
      await _db.updateBook(book);
      _books = _books.map((b) => b.id == book.id ? book : b).toList();
      _applyFilters();
    } catch (e) {
      _error = 'Failed to update book: $e';
      debugPrint('LibraryProvider: updateBook error: $e');
      notifyListeners();
    }
  }

  /// Deletes a book from the library by id.
  Future<void> deleteBook(String id) async {
    try {
      await _db.deleteBook(id);
      _books.removeWhere((b) => b.id == id);
      _applyFilters();
    } catch (e) {
      _error = 'Failed to delete book: $e';
      debugPrint('LibraryProvider: deleteBook error: $e');
      notifyListeners();
    }
  }

  /// Imports a book from a local file path.
  ///
  /// Determines the file type, extracts metadata, copies the file to
  /// app storage, and creates a [Book] object in the library.
  Future<Book?> importBook(String filePath, {String? fileType}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final book = await BookImportService.importFile(filePath);
      await _db.insertBook(book);
      _books.insert(0, book);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return book;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to import book: $e';
      debugPrint('LibraryProvider: importBook error: $e');
      notifyListeners();
      return null;
    }
  }

  /// Imports a book from a URL (downloads then imports).
  Future<Book?> importFromUrl(String url) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // This would typically delegate to BookDownloadService
      // For now, create a minimal book placeholder
      final book = Book(
        id: _uuid.v4(),
        title: url.split('/').last,
        author: 'Unknown',
        source: BookSource.url,
        sourceUrl: url,
        addedAt: DateTime.now(),
        isDownloaded: false,
      );
      await _db.insertBook(book);
      _books.insert(0, book);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return book;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to import from URL: $e';
      debugPrint('LibraryProvider: importFromUrl error: $e');
      notifyListeners();
      return null;
    }
  }

  /// Sets the search query and filters the list.
  void searchBooks(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Sets the sort criteria.
  void setSortBy(LibrarySortBy sort) {
    _sortBy = sort;
    _applyFilters();
  }

  /// Sets the filter status.
  void setFilterStatus(LibraryFilterStatus status) {
    _filterStatus = status;
    _applyFilters();
  }

  /// Sets the view mode (grid or list).
  void setViewMode(LibraryViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  /// Gets a book by id.
  Future<Book?> getBookById(String id) async {
    try {
      // Check in-memory first
      final cached = _books.where((b) => b.id == id).toList();
      if (cached.isNotEmpty) return cached.first;
      return _db.getBookById(id);
    } catch (e) {
      debugPrint('LibraryProvider: getBookById error: $e');
      return null;
    }
  }

  /// Returns books the user is currently reading.
  List<Book> getContinueReading() {
    return _books
        .where((b) =>
            b.readingStatus == ReadingStatus.currentlyReading &&
            b.lastOpenedAt != null)
        .toList()
      ..sort((a, b) => (b.lastOpenedAt ?? DateTime(2000))
          .compareTo(a.lastOpenedAt ?? DateTime(2000)));
  }

  /// Returns recently added books.
  List<Book> getRecentlyAdded({int limit = 10}) {
    final sorted = List<Book>.from(_books)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted.take(limit).toList();
  }

  /// Returns books the user is currently reading.
  List<Book> getCurrentlyReading() {
    return _books
        .where((b) => b.readingStatus == ReadingStatus.currentlyReading)
        .toList();
  }

  /// Marks a book as currently reading.
  Future<void> markAsReading(String bookId) async {
    try {
      final book = _books.where((b) => b.id == bookId).firstOrNull;
      if (book == null) return;
      final updated = book.copyWith(
        readingStatus: ReadingStatus.currentlyReading,
        lastOpenedAt: DateTime.now(),
      );
      await _db.updateBook(updated);
      _books = _books.map((b) => b.id == bookId ? updated : b).toList();
      _applyFilters();
    } catch (e) {
      _error = 'Failed to mark as reading: $e';
      debugPrint('LibraryProvider: markAsReading error: $e');
      notifyListeners();
    }
  }

  /// Marks a book as completed.
  Future<void> markAsCompleted(String bookId) async {
    try {
      final book = _books.where((b) => b.id == bookId).firstOrNull;
      if (book == null) return;
      final updated = book.copyWith(
        readingStatus: ReadingStatus.completed,
        readingProgress: 1.0,
        currentPage: book.pageCount ?? book.currentPage,
      );
      await _db.updateBook(updated);
      _books = _books.map((b) => b.id == bookId ? updated : b).toList();
      _applyFilters();
    } catch (e) {
      _error = 'Failed to mark as completed: $e';
      debugPrint('LibraryProvider: markAsCompleted error: $e');
      notifyListeners();
    }
  }

  /// Toggles favorite status for a book.
  Future<void> markAsFavorite(String bookId) async {
    try {
      final book = _books.where((b) => b.id == bookId).firstOrNull;
      if (book == null) return;
      final isFav = book.readingStatus == ReadingStatus.favorite;
      final updated = book.copyWith(
        readingStatus:
            isFav ? ReadingStatus.wantToRead : ReadingStatus.favorite,
      );
      await _db.updateBook(updated);
      _books = _books.map((b) => b.id == bookId ? updated : b).toList();
      _applyFilters();
    } catch (e) {
      _error = 'Failed to toggle favorite: $e';
      debugPrint('LibraryProvider: markAsFavorite error: $e');
      notifyListeners();
    }
  }

  /// Updates reading progress for a book.
  Future<void> updateReadingProgress(
      String bookId, int page, double progress) async {
    try {
      final book = _books.where((b) => b.id == bookId).firstOrNull;
      if (book == null) return;
      final updated = book.copyWith(
        currentPage: page,
        readingProgress: progress.clamp(0.0, 1.0),
        lastOpenedAt: DateTime.now(),
      );
      await _db.updateBook(updated);
      _books = _books.map((b) => b.id == bookId ? updated : b).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update progress: $e';
      debugPrint('LibraryProvider: updateReadingProgress error: $e');
      notifyListeners();
    }
  }

  /// Returns the last opened book, or null if none.
  Book? getLastOpenedBook() {
    final opened = _books
        .where((b) => b.lastOpenedAt != null)
        .toList()
      ..sort((a, b) => (b.lastOpenedAt ?? DateTime(2000))
          .compareTo(a.lastOpenedAt ?? DateTime(2000)));
    return opened.isNotEmpty ? opened.first : null;
  }

  /// Returns the filtered + sorted book list.
  List<Book> get filteredBooks {
    List<Book> result = List<Book>.from(_books);

    // Filter by status
    switch (_filterStatus) {
      case LibraryFilterStatus.all:
        break;
      case LibraryFilterStatus.wantToRead:
        result = result
            .where((b) => b.readingStatus == ReadingStatus.wantToRead)
            .toList();
        break;
      case LibraryFilterStatus.currentlyReading:
        result = result
            .where(
                (b) => b.readingStatus == ReadingStatus.currentlyReading)
            .toList();
        break;
      case LibraryFilterStatus.completed:
        result = result
            .where((b) => b.readingStatus == ReadingStatus.completed)
            .toList();
        break;
      case LibraryFilterStatus.favorite:
        result = result
            .where((b) => b.readingStatus == ReadingStatus.favorite)
            .toList();
        break;
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.author.toLowerCase().contains(q) ||
              b.description.toLowerCase().contains(q))
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case LibrarySortBy.title:
        result.sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case LibrarySortBy.author:
        result.sort((a, b) =>
            a.author.toLowerCase().compareTo(b.author.toLowerCase()));
        break;
      case LibrarySortBy.date:
        result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case LibrarySortBy.progress:
        result.sort((a, b) =>
            b.readingProgress.compareTo(a.readingProgress));
        break;
    }

    return result;
  }

  /// Returns total book count.
  int get totalCount => _books.length;

  /// Returns count by status.
  int getCountByStatus(ReadingStatus status) {
    return _books.where((b) => b.readingStatus == status).length;
  }

  void _applyFilters() {
    notifyListeners();
  }

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Extension to add `firstOrNull` to Iterable since it's not available
/// in all Dart SDK versions.
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
