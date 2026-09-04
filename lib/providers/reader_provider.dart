/// Reader provider for the Libora reading ecosystem.
///
/// Manages the active reading session: current book, page navigation,
/// controls visibility, bookmarks, TOC, highlights, and reader settings.
/// Delegates persistence to [DatabaseHelper].
library;

import 'package:flutter/foundation.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/bookmark_model.dart';
import 'package:libora/data/models/chapter_model.dart';
import 'package:libora/data/models/highlight_model.dart';
import 'package:libora/providers/settings_provider.dart';
import 'package:libora/services/epub_parser_service.dart';
import 'package:uuid/uuid.dart';

class ReaderProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  Book? _currentBook;
  Book? get currentBook => _currentBook;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  int _totalPages = 0;
  int get totalPages => _totalPages;

  bool _isControlsVisible = true;
  bool get isControlsVisible => _isControlsVisible;

  List<Bookmark> _bookmarks = [];
  List<Bookmark> get bookmarks => _bookmarks;

  List<Chapter> _toc = [];
  List<Chapter> get toc => _toc;

  List<Highlight> _highlights = [];
  List<Highlight> get highlights => _highlights;

  // ── Reader settings (synced with SettingsProvider) ──
  double _fontSize = 18.0;
  double get fontSize => _fontSize;

  String _fontFamily = 'Serif';
  String get fontFamily => _fontFamily;

  double _lineSpacing = 1.5;
  double get lineSpacing => _lineSpacing;

  double _margins = 16.0;
  double get margins => _margins;

  ReaderTheme _readerTheme = ReaderTheme.light;
  ReaderTheme get readerTheme => _readerTheme;

  ReaderTextAlignment _textAlignment = ReaderTextAlignment.justify;
  ReaderTextAlignment get textAlignment => _textAlignment;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Opens a book for reading. Loads bookmarks, highlights, and TOC.
  Future<void> openBook(Book book) async {
    _currentBook = book;
    _currentPage = book.currentPage;
    _totalPages = book.pageCount ?? 0;
    _isLoading = true;
    notifyListeners();

    try {
      // Load bookmarks
      _bookmarks = await _db.getBookmarksByBook(book.id);

      // Load highlights
      _highlights = await _db.getHighlightsByBook(book.id);

      // Load TOC for EPUB books
      if (book.fileType == BookFileType.epub && book.filePath != null) {
        final epubData = await EpubParserService.parseEpub(book.filePath!);
        _toc = epubData.chapters;
        _totalPages = _totalPages == 0
            ? epubData.chapters.length
            : _totalPages;
      }

      // Update last opened
      final updated = book.copyWith(lastOpenedAt: DateTime.now());
      await _db.updateBook(updated);
      _currentBook = updated;
    } catch (e) {
      _error = 'Failed to open book: $e';
      debugPrint('ReaderProvider: openBook error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the total page count for the current document.
  void setTotalPages(int total) {
    if (total > 0 && _totalPages != total) {
      _totalPages = total;
      notifyListeners();
    }
  }

  /// Closes the current book and resets state.
  void closeBook() {
    _currentBook = null;
    _currentPage = 0;
    _totalPages = 0;
    _bookmarks = [];
    _toc = [];
    _highlights = [];
    _isControlsVisible = true;
    notifyListeners();
  }

  /// Navigate to the next page.
  Future<void> nextPage() async {
    if (_currentPage < _totalPages - 1) {
      _currentPage++;
      await _updateProgress();
      notifyListeners();
    }
  }

  /// Navigate to the previous page.
  Future<void> previousPage() async {
    if (_currentPage > 0) {
      _currentPage--;
      await _updateProgress();
      notifyListeners();
    }
  }

  /// Navigate to a specific page.
  Future<void> goToPage(int page) async {
    if (page >= 0 && page < _totalPages) {
      _currentPage = page;
      await _updateProgress();
      notifyListeners();
    }
  }

  /// Toggles the visibility of reader controls (toolbar, etc.).
  void toggleControls() {
    _isControlsVisible = !_isControlsVisible;
    notifyListeners();
  }

  /// Adds a bookmark at the current page.
  Future<void> addBookmark(String? title) async {
    if (_currentBook == null) return;

    try {
      final bookmark = Bookmark(
        id: _uuid.v4(),
        bookId: _currentBook!.id,
        page: _currentPage,
        location: 'page_$_currentPage',
        chapter: _currentChapterTitle,
        title: title,
        createdAt: DateTime.now(),
      );
      await _db.insertBookmark(bookmark);
      _bookmarks.add(bookmark);
      _bookmarks.sort((a, b) => a.page.compareTo(b.page));
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add bookmark: $e';
      debugPrint('ReaderProvider: addBookmark error: $e');
      notifyListeners();
    }
  }

  /// Removes a bookmark by id.
  Future<void> removeBookmark(String id) async {
    try {
      await _db.deleteBookmark(id);
      _bookmarks.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove bookmark: $e';
      debugPrint('ReaderProvider: removeBookmark error: $e');
      notifyListeners();
    }
  }

  /// Alias for removeBookmark
  Future<void> deleteBookmark(String id) => removeBookmark(id);

  /// Loads bookmarks for the current book.
  Future<void> getBookmarks() async {
    if (_currentBook == null) return;
    try {
      _bookmarks = await _db.getBookmarksByBook(_currentBook!.id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load bookmarks: $e';
      debugPrint('ReaderProvider: getBookmarks error: $e');
    }
  }

  /// Updates reading progress in the database.
  Future<void> _updateProgress() async {
    if (_currentBook == null) return;
    try {
      final progress = _totalPages > 0
          ? (_currentPage + 1) / _totalPages
          : 0.0;
      final updated = _currentBook!.copyWith(
        currentPage: _currentPage,
        readingProgress: progress.clamp(0.0, 1.0),
        lastOpenedAt: DateTime.now(),
      );
      await _db.updateBook(updated);
      _currentBook = updated;
    } catch (e) {
      debugPrint('ReaderProvider: _updateProgress error: $e');
    }
  }

  /// Explicitly update progress (e.g. for external calls).
  Future<void> updateProgress() async {
    await _updateProgress();
    notifyListeners();
  }

  /// Gets the table of contents for the current book.
  Future<void> getTOC() async {
    if (_currentBook == null) return;
    if (_currentBook!.fileType != BookFileType.epub ||
        _currentBook!.filePath == null) return;

    try {
      final epubData =
          await EpubParserService.parseEpub(_currentBook!.filePath!);
      _toc = epubData.chapters;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load TOC: $e';
      debugPrint('ReaderProvider: getTOC error: $e');
      notifyListeners();
    }
  }

  /// Navigates to a specific chapter.
  Future<void> goToChapter(Chapter chapter) async {
    try {
      // Find the chapter's page index based on order
      final chapterIndex = _toc.indexWhere((c) => c.id == chapter.id);
      if (chapterIndex >= 0 && chapterIndex < _totalPages) {
        _currentPage = chapterIndex;
        await _updateProgress();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to navigate to chapter: $e';
      debugPrint('ReaderProvider: goToChapter error: $e');
      notifyListeners();
    }
  }

  /// Saves a highlight at the current page.
  Future<Highlight?> saveHighlight(
    String text,
    String color,
    int page,
    String? chapter,
  ) async {
    if (_currentBook == null) return null;

    try {
      final highlight = Highlight(
        id: _uuid.v4(),
        bookId: _currentBook!.id,
        selectedText: text,
        color: color,
        page: page,
        location: 'page_$page',
        chapter: chapter,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _db.insertHighlight(highlight);
      _highlights.add(highlight);
      _highlights.sort((a, b) => a.page.compareTo(b.page));
      notifyListeners();
      return highlight;
    } catch (e) {
      _error = 'Failed to save highlight: $e';
      debugPrint('ReaderProvider: saveHighlight error: $e');
      notifyListeners();
      return null;
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
      debugPrint('ReaderProvider: updateHighlight error: $e');
      notifyListeners();
    }
  }

  /// Removes a highlight by id.
  Future<void> removeHighlight(String id) async {
    try {
      await _db.deleteHighlight(id);
      _highlights.removeWhere((h) => h.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove highlight: $e';
      debugPrint('ReaderProvider: removeHighlight error: $e');
      notifyListeners();
    }
  }

  // ── Reader Settings ──

  /// Applies settings from [SettingsProvider].
  void applySettings(SettingsProvider settings) {
    _fontSize = settings.fontSize;
    _fontFamily = settings.fontFamily;
    _lineSpacing = settings.lineSpacing;
    _margins = settings.margins;
    _readerTheme = settings.readerTheme;
    _textAlignment = settings.textAlignment;
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setFontFamily(String family) {
    _fontFamily = family;
    notifyListeners();
  }

  void setLineSpacing(double spacing) {
    _lineSpacing = spacing;
    notifyListeners();
  }

  void setMargins(double margins) {
    _margins = margins;
    notifyListeners();
  }

  void setReaderTheme(ReaderTheme theme) {
    _readerTheme = theme;
    notifyListeners();
  }

  void setTextAlignment(ReaderTextAlignment alignment) {
    _textAlignment = alignment;
    notifyListeners();
  }

  /// Returns the title of the current chapter based on page position.
  String? get _currentChapterTitle {
    if (_toc.isEmpty) return null;
    for (final chapter in _toc) {
      if (chapter.order == _currentPage) return chapter.title;
    }
    return _toc.isNotEmpty ? _toc.first.title : null;
  }

  /// Returns the reading progress as a percentage (0–100).
  double get progressPercent {
    if (_totalPages == 0) return 0;
    return ((_currentPage + 1) / _totalPages * 100).clamp(0, 100);
  }

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
