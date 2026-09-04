/// SQLite database helper for the Libora reading ecosystem.
///
/// Implements a singleton pattern for managing the SQLite database lifecycle.
/// Handles table creation, migrations, and CRUD operations for all entities:
/// books, highlights, notes, quotes, collections, bookmarks, reading_stats,
/// and the collection_books junction table.
library;

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

import '../models/book_model.dart';
import '../models/bookmark_model.dart';
import '../models/collection_model.dart';
import '../models/highlight_model.dart';
import '../models/note_model.dart';
import '../models/quote_model.dart';
import '../models/reading_stats_model.dart';

/// Singleton helper that wraps all SQLite database operations.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper _instance = DatabaseHelper._();

  /// Returns the singleton instance.
  factory DatabaseHelper() => _instance;
  static DatabaseHelper get instance => _instance;

  static Database? _database;

  /// The current database version. Increment when adding migrations.
  static const int _databaseVersion = 1;

  /// The database file name.
  static const String _databaseName = 'libora.db';

  // ──────────────────────────────────────────────
  // Table Names
  // ──────────────────────────────────────────────

  static const String tableBooks = 'books';
  static const String tableHighlights = 'highlights';
  static const String tableNotes = 'notes';
  static const String tableQuotes = 'quotes';
  static const String tableCollections = 'collections';
  static const String tableBookmarks = 'bookmarks';
  static const String tableReadingStats = 'reading_stats';
  static const String tableCollectionBooks = 'collection_books';

  // ──────────────────────────────────────────────
  // Initialization
  // ──────────────────────────────────────────────

  /// Returns the database instance, opening it if necessary.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
    );
  }

  /// Enables foreign key constraints on every connection.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Creates all tables when the database is first created.
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // ── Books ──
    batch.execute('''
      CREATE TABLE $tableBooks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        cover_path TEXT,
        cover_url TEXT,
        file_path TEXT,
        file_type TEXT NOT NULL DEFAULT 'pdf',
        file_size INTEGER NOT NULL DEFAULT 0,
        page_count INTEGER,
        current_page INTEGER NOT NULL DEFAULT 0,
        reading_progress REAL NOT NULL DEFAULT 0.0,
        reading_status TEXT NOT NULL DEFAULT 'wantToRead',
        last_opened_at TEXT,
        added_at TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'import',
        source_url TEXT,
        publisher TEXT,
        publish_year INTEGER,
        isbn TEXT,
        language TEXT,
        genres TEXT NOT NULL DEFAULT '',
        tags TEXT NOT NULL DEFAULT '',
        is_downloaded INTEGER NOT NULL DEFAULT 0,
        is_available_offline INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute(
        'CREATE INDEX idx_books_status ON $tableBooks(reading_status)');
    batch.execute('CREATE INDEX idx_books_added ON $tableBooks(added_at)');
    batch.execute(
        'CREATE INDEX idx_books_last_opened ON $tableBooks(last_opened_at)');

    // ── Highlights ──
    batch.execute('''
      CREATE TABLE $tableHighlights (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        selected_text TEXT NOT NULL,
        color TEXT NOT NULL DEFAULT '#FFEB3B',
        page INTEGER NOT NULL DEFAULT 0,
        location TEXT NOT NULL DEFAULT '',
        chapter TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES $tableBooks(id) ON DELETE CASCADE
      )
    ''');
    batch.execute(
        'CREATE INDEX idx_highlights_book ON $tableHighlights(book_id)');
    batch.execute(
        'CREATE INDEX idx_highlights_created ON $tableHighlights(created_at)');

    // ── Notes ──
    batch.execute('''
      CREATE TABLE $tableNotes (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        highlight_id TEXT,
        content TEXT NOT NULL DEFAULT '',
        selected_text TEXT NOT NULL DEFAULT '',
        page INTEGER NOT NULL DEFAULT 0,
        location TEXT NOT NULL DEFAULT '',
        chapter TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES $tableBooks(id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_notes_book ON $tableNotes(book_id)');
    batch.execute(
        'CREATE INDEX idx_notes_highlight ON $tableNotes(highlight_id)');
    batch.execute('CREATE INDEX idx_notes_created ON $tableNotes(created_at)');

    // ── Quotes ──
    batch.execute('''
      CREATE TABLE $tableQuotes (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        quote_text TEXT NOT NULL,
        book_title TEXT NOT NULL DEFAULT '',
        author TEXT NOT NULL DEFAULT '',
        page INTEGER NOT NULL DEFAULT 0,
        location TEXT NOT NULL DEFAULT '',
        chapter TEXT,
        personal_thought TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES $tableBooks(id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_quotes_book ON $tableQuotes(book_id)');
    batch.execute('CREATE INDEX idx_quotes_fav ON $tableQuotes(is_favorite)');
    batch.execute('CREATE INDEX idx_quotes_created ON $tableQuotes(created_at)');

    // ── Collections ──
    batch.execute('''
      CREATE TABLE $tableCollections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        color TEXT NOT NULL DEFAULT '#1976D2',
        book_ids TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ── Collection-Books junction table ──
    batch.execute('''
      CREATE TABLE $tableCollectionBooks (
        collection_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        added_at TEXT NOT NULL,
        PRIMARY KEY (collection_id, book_id),
        FOREIGN KEY (collection_id) REFERENCES $tableCollections(id) ON DELETE CASCADE,
        FOREIGN KEY (book_id) REFERENCES $tableBooks(id) ON DELETE CASCADE
      )
    ''');
    batch.execute(
        'CREATE INDEX idx_cb_collection ON $tableCollectionBooks(collection_id)');
    batch.execute(
        'CREATE INDEX idx_cb_book ON $tableCollectionBooks(book_id)');

    // ── Bookmarks ──
    batch.execute('''
      CREATE TABLE $tableBookmarks (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        page INTEGER NOT NULL DEFAULT 0,
        location TEXT NOT NULL DEFAULT '',
        chapter TEXT,
        title TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES $tableBooks(id) ON DELETE CASCADE
      )
    ''');
    batch.execute(
        'CREATE INDEX idx_bookmarks_book ON $tableBookmarks(book_id)');

    // ── Reading Stats ──
    batch.execute('''
      CREATE TABLE $tableReadingStats (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        date TEXT NOT NULL,
        pages_read INTEGER NOT NULL DEFAULT 0,
        reading_time_seconds INTEGER NOT NULL DEFAULT 0,
        current_page INTEGER NOT NULL DEFAULT 0,
        session_id TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES $tableBooks(id) ON DELETE CASCADE
      )
    ''');
    batch.execute(
        'CREATE INDEX idx_stats_book ON $tableReadingStats(book_id)');
    batch.execute(
        'CREATE INDEX idx_stats_date ON $tableReadingStats(date)');
    batch.execute(
        'CREATE INDEX idx_stats_session ON $tableReadingStats(session_id)');

    await batch.commit();
  }

  /// Handles database migrations when [version] is upgraded.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example migration for future versions:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE $tableBooks ADD COLUMN new_field TEXT');
    // }
    // For now, v1 has no migrations.
  }

  /// Handles database downgrade by dropping and recreating.
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    await _onUpgrade(db, oldVersion, newVersion);
  }

  /// Closes the database. Call this when the app is shutting down.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  // ══════════════════════════════════════════════
  // BOOKS CRUD
  // ══════════════════════════════════════════════

  /// Inserts a [Book]. Returns the row id.
  Future<int> insertBook(Book book) async {
    final db = await database;
    return db.insert(tableBooks, book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Inserts or replaces a [Book] by id.
  Future<int> upsertBook(Book book) async {
    final db = await database;
    return db.insert(tableBooks, book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates a [Book] by id. Returns the number of rows affected.
  Future<int> updateBook(Book book) async {
    final db = await database;
    return db.update(
      tableBooks,
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  /// Deletes a [Book] by id. Returns the number of rows deleted.
  Future<int> deleteBook(String id) async {
    final db = await database;
    return db.delete(tableBooks, where: 'id = ?', whereArgs: [id]);
  }

  /// Returns a single [Book] by id, or null if not found.
  Future<Book?> getBookById(String id) async {
    final db = await database;
    final maps = await db.query(tableBooks, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Book.fromMap(maps.first);
  }

  /// Returns all books in the library.
  Future<List<Book>> getAllBooks() async {
    final db = await database;
    final maps =
        await db.query(tableBooks, orderBy: 'added_at DESC');
    return maps.map(Book.fromMap).toList();
  }

  /// Returns books filtered by [ReadingStatus].
  Future<List<Book>> getBooksByStatus(ReadingStatus status) async {
    final db = await database;
    final maps = await db.query(
      tableBooks,
      where: 'reading_status = ?',
      whereArgs: [status.name],
      orderBy: 'added_at DESC',
    );
    return maps.map(Book.fromMap).toList();
  }

  /// Returns books the user is currently reading, ordered by last opened.
  Future<List<Book>> getContinueReadingBooks({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      tableBooks,
      where: "reading_status = ? AND last_opened_at IS NOT NULL",
      whereArgs: [ReadingStatus.currentlyReading.name],
      orderBy: 'last_opened_at DESC',
      limit: limit,
    );
    return maps.map(Book.fromMap).toList();
  }

  /// Returns recently added books, ordered by [addedAt] descending.
  Future<List<Book>> getRecentlyAddedBooks({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      tableBooks,
      orderBy: 'added_at DESC',
      limit: limit,
    );
    return maps.map(Book.fromMap).toList();
  }

  /// Full-text search across title, author, description, genres, and tags.
  Future<List<Book>> searchBooks(String query) async {
    final db = await database;
    final searchPattern = '%$query%';
    final maps = await db.query(
      tableBooks,
      where:
          'title LIKE ? OR author LIKE ? OR description LIKE ? OR genres LIKE ? OR tags LIKE ?',
      whereArgs: [
        searchPattern,
        searchPattern,
        searchPattern,
        searchPattern,
        searchPattern,
      ],
      orderBy: 'added_at DESC',
    );
    return maps.map(Book.fromMap).toList();
  }

  /// Returns books belonging to a specific collection, using the junction
  /// table for referential integrity.
  Future<List<Book>> getBooksByCollection(String collectionId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT b.* FROM $tableBooks b
      INNER JOIN $tableCollectionBooks cb ON cb.book_id = b.id
      WHERE cb.collection_id = ?
      ORDER BY cb.sort_order ASC
    ''', [collectionId]);
    return maps.map(Book.fromMap).toList();
  }

  /// Returns favorite books (reading_status = 'favorite').
  Future<List<Book>> getFavoriteBooks() async {
    return getBooksByStatus(ReadingStatus.favorite);
  }

  // ══════════════════════════════════════════════
  // HIGHLIGHTS CRUD
  // ══════════════════════════════════════════════

  /// Inserts a [Highlight]. Returns the row id.
  Future<int> insertHighlight(Highlight highlight) async {
    final db = await database;
    return db.insert(tableHighlights, highlight.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates a [Highlight] by id.
  Future<int> updateHighlight(Highlight highlight) async {
    final db = await database;
    return db.update(
      tableHighlights,
      highlight.toMap(),
      where: 'id = ?',
      whereArgs: [highlight.id],
    );
  }

  /// Deletes a [Highlight] by id.
  Future<int> deleteHighlight(String id) async {
    final db = await database;
    return db.delete(tableHighlights, where: 'id = ?', whereArgs: [id]);
  }

  /// Returns a single [Highlight] by id.
  Future<Highlight?> getHighlightById(String id) async {
    final db = await database;
    final maps =
        await db.query(tableHighlights, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Highlight.fromMap(maps.first);
  }

  /// Returns all highlights for a given book, ordered by page then creation.
  Future<List<Highlight>> getHighlightsByBook(String bookId) async {
    final db = await database;
    final maps = await db.query(
      tableHighlights,
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'page ASC, created_at DESC',
    );
    return maps.map(Highlight.fromMap).toList();
  }

  /// Returns recent highlights across all books, ordered by creation.
  Future<List<Highlight>> getRecentHighlights({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      tableHighlights,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map(Highlight.fromMap).toList();
  }

  /// Searches highlights by selected text content.
  Future<List<Highlight>> searchHighlights(String query) async {
    final db = await database;
    final maps = await db.query(
      tableHighlights,
      where: 'selected_text LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map(Highlight.fromMap).toList();
  }

  // ══════════════════════════════════════════════
  // NOTES CRUD
  // ══════════════════════════════════════════════

  /// Inserts a [Note]. Returns the row id.
  Future<int> insertNote(Note note) async {
    final db = await database;
    return db.insert(tableNotes, note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates a [Note] by id.
  Future<int> updateNote(Note note) async {
    final db = await database;
    return db.update(
      tableNotes,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// Deletes a [Note] by id.
  Future<int> deleteNote(String id) async {
    final db = await database;
    return db.delete(tableNotes, where: 'id = ?', whereArgs: [id]);
  }

  /// Returns a single [Note] by id.
  Future<Note?> getNoteById(String id) async {
    final db = await database;
    final maps = await db.query(tableNotes, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  /// Returns all notes for a given book.
  Future<List<Note>> getNotesByBook(String bookId) async {
    final db = await database;
    final maps = await db.query(
      tableNotes,
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'page ASC, created_at DESC',
    );
    return maps.map(Note.fromMap).toList();
  }

  /// Returns notes linked to a specific highlight.
  Future<List<Note>> getNotesByHighlight(String highlightId) async {
    final db = await database;
    final maps = await db.query(
      tableNotes,
      where: 'highlight_id = ?',
      whereArgs: [highlightId],
      orderBy: 'created_at DESC',
    );
    return maps.map(Note.fromMap).toList();
  }

  /// Returns recent notes across all books.
  Future<List<Note>> getRecentNotes({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      tableNotes,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map(Note.fromMap).toList();
  }

  /// Searches notes by content or selected text.
  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final maps = await db.query(
      tableNotes,
      where: 'content LIKE ? OR selected_text LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map(Note.fromMap).toList();
  }

  // ══════════════════════════════════════════════
  // QUOTES CRUD
  // ══════════════════════════════════════════════

  /// Inserts a [Quote]. Returns the row id.
  Future<int> insertQuote(Quote quote) async {
    final db = await database;
    return db.insert(tableQuotes, quote.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates a [Quote] by id.
  Future<int> updateQuote(Quote quote) async {
    final db = await database;
    return db.update(
      tableQuotes,
      quote.toMap(),
      where: 'id = ?',
      whereArgs: [quote.id],
    );
  }

  /// Deletes a [Quote] by id.
  Future<int> deleteQuote(String id) async {
    final db = await database;
    return db.delete(tableQuotes, where: 'id = ?', whereArgs: [id]);
  }

  /// Returns a single [Quote] by id.
  Future<Quote?> getQuoteById(String id) async {
    final db = await database;
    final maps = await db.query(tableQuotes, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Quote.fromMap(maps.first);
  }

  /// Returns all quotes for a given book.
  Future<List<Quote>> getQuotesByBook(String bookId) async {
    final db = await database;
    final maps = await db.query(
      tableQuotes,
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'page ASC, created_at DESC',
    );
    return maps.map(Quote.fromMap).toList();
  }

  /// Returns recent quotes across all books.
  Future<List<Quote>> getRecentQuotes({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      tableQuotes,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map(Quote.fromMap).toList();
  }

  /// Returns favorite quotes only.
  Future<List<Quote>> getFavoriteQuotes() async {
    final db = await database;
    final maps = await db.query(
      tableQuotes,
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map(Quote.fromMap).toList();
  }

  /// Searches quotes by text content.
  Future<List<Quote>> searchQuotes(String query) async {
    final db = await database;
    final maps = await db.query(
      tableQuotes,
      where: 'quote_text LIKE ? OR personal_thought LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map(Quote.fromMap).toList();
  }

  // ══════════════════════════════════════════════
  // COLLECTIONS CRUD
  // ══════════════════════════════════════════════

  /// Inserts a [Collection]. Returns the row id.
  Future<int> insertCollection(Collection collection) async {
    final db = await database;
    return db.insert(tableCollections, collection.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates a [Collection] by id.
  Future<int> updateCollection(Collection collection) async {
    final db = await database;
    return db.update(
      tableCollections,
      collection.toMap(),
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  /// Deletes a [Collection] by id. The junction table rows are cascade-deleted.
  Future<int> deleteCollection(String id) async {
    final db = await database;
    return db.delete(tableCollections, where: 'id = ?', whereArgs: [id]);
  }

  /// Returns a single [Collection] by id.
  Future<Collection?> getCollectionById(String id) async {
    final db = await database;
    final maps =
        await db.query(tableCollections, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Collection.fromMap(maps.first);
  }

  /// Returns all collections.
  Future<List<Collection>> getAllCollections() async {
    final db = await database;
    final maps =
        await db.query(tableCollections, orderBy: 'updated_at DESC');
    return maps.map(Collection.fromMap).toList();
  }

  /// Adds a book to a collection (junction table).
  Future<void> addBookToCollection(
    String collectionId,
    String bookId, {
    int sortOrder = 0,
  }) async {
    final db = await database;
    await db.insert(
      tableCollectionBooks,
      {
        'collection_id': collectionId,
        'book_id': bookId,
        'sort_order': sortOrder,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Removes a book from a collection (junction table).
  Future<int> removeBookFromCollection(
      String collectionId, String bookId) async {
    final db = await database;
    return db.delete(
      tableCollectionBooks,
      where: 'collection_id = ? AND book_id = ?',
      whereArgs: [collectionId, bookId],
    );
  }

  /// Searches collections by name or description.
  Future<List<Collection>> searchCollections(String query) async {
    final db = await database;
    final maps = await db.query(
      tableCollections,
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return maps.map(Collection.fromMap).toList();
  }

  // ══════════════════════════════════════════════
  // BOOKMARKS CRUD
  // ══════════════════════════════════════════════

  /// Inserts a [Bookmark]. Returns the row id.
  Future<int> insertBookmark(Bookmark bookmark) async {
    final db = await database;
    return db.insert(tableBookmarks, bookmark.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates a [Bookmark] by id.
  Future<int> updateBookmark(Bookmark bookmark) async {
    final db = await database;
    return db.update(
      tableBookmarks,
      bookmark.toMap(),
      where: 'id = ?',
      whereArgs: [bookmark.id],
    );
  }

  /// Deletes a [Bookmark] by id.
  Future<int> deleteBookmark(String id) async {
    final db = await database;
    return db.delete(tableBookmarks, where: 'id = ?', whereArgs: [id]);
  }

  /// Returns a single [Bookmark] by id.
  Future<Bookmark?> getBookmarkById(String id) async {
    final db = await database;
    final maps =
        await db.query(tableBookmarks, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Bookmark.fromMap(maps.first);
  }

  /// Returns all bookmarks for a given book.
  Future<List<Bookmark>> getBookmarksByBook(String bookId) async {
    final db = await database;
    final maps = await db.query(
      tableBookmarks,
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'page ASC, created_at DESC',
    );
    return maps.map(Bookmark.fromMap).toList();
  }

  /// Returns all bookmarks across all books.
  Future<List<Bookmark>> getAllBookmarks() async {
    final db = await database;
    final maps =
        await db.query(tableBookmarks, orderBy: 'created_at DESC');
    return maps.map(Bookmark.fromMap).toList();
  }

  // ══════════════════════════════════════════════
  // READING STATS CRUD
  // ══════════════════════════════════════════════

  /// Inserts a [ReadingStats] entry. Returns the row id.
  Future<int> insertReadingStats(ReadingStats stats) async {
    final db = await database;
    return db.insert(tableReadingStats, stats.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates a [ReadingStats] entry by id.
  Future<int> updateReadingStats(ReadingStats stats) async {
    final db = await database;
    return db.update(
      tableReadingStats,
      stats.toMap(),
      where: 'id = ?',
      whereArgs: [stats.id],
    );
  }

  /// Deletes a [ReadingStats] entry by id.
  Future<int> deleteReadingStats(String id) async {
    final db = await database;
    return db.delete(tableReadingStats, where: 'id = ?', whereArgs: [id]);
  }

  /// Returns a single [ReadingStats] by id.
  Future<ReadingStats?> getReadingStatsById(String id) async {
    final db = await database;
    final maps =
        await db.query(tableReadingStats, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ReadingStats.fromMap(maps.first);
  }

  /// Returns all reading stats for a given book, ordered by date.
  Future<List<ReadingStats>> getReadingStatsByBook(String bookId) async {
    final db = await database;
    final maps = await db.query(
      tableReadingStats,
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'date ASC',
    );
    return maps.map(ReadingStats.fromMap).toList();
  }

  /// Returns reading stats for a specific date (ISO 8601 date string).
  ///
  /// Pass the date portion only (e.g., "2026-09-04") to match all sessions
  /// recorded on that day.
  Future<List<ReadingStats>> getReadingStatsByDate(String dateString) async {
    final db = await database;
    final maps = await db.query(
      tableReadingStats,
      where: 'date LIKE ?',
      whereArgs: ['$dateString%'],
      orderBy: 'date ASC',
    );
    return maps.map(ReadingStats.fromMap).toList();
  }

  /// Returns reading stats within a date range (inclusive).
  ///
  /// Both [startDate] and [endDate] should be ISO 8601 strings.
  Future<List<ReadingStats>> getReadingStatsByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final maps = await db.query(
      tableReadingStats,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map(ReadingStats.fromMap).toList();
  }

  /// Returns all reading stats, ordered by date.
  Future<List<ReadingStats>> getAllReadingStats() async {
    final db = await database;
    final maps =
        await db.query(tableReadingStats, orderBy: 'date DESC');
    return maps.map(ReadingStats.fromMap).toList();
  }

  /// Returns the total pages read and total reading time for a book.
  Future<({int totalPages, int totalSeconds})> getBookReadingSummary(
      String bookId) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(pages_read), 0) AS total_pages,
        COALESCE(SUM(reading_time_seconds), 0) AS total_seconds
      FROM $tableReadingStats
      WHERE book_id = ?
      ''',
      [bookId],
    );
    if (results.isEmpty) {
      return (totalPages: 0, totalSeconds: 0);
    }
    final row = results.first;
    return (
      totalPages: (row['total_pages'] as int?) ?? 0,
      totalSeconds: (row['total_seconds'] as int?) ?? 0,
    );
  }

  // ══════════════════════════════════════════════
  // GENERIC / UTILITY
  // ══════════════════════════════════════════════

  /// Clears all data from all tables. Use with caution (e.g., for a
  /// "reset library" feature). Returns the number of rows deleted.
  Future<int> clearAllData() async {
    final db = await database;
    int total = 0;
    total += await db.delete(tableCollectionBooks);
    total += await db.delete(tableReadingStats);
    total += await db.delete(tableBookmarks);
    total += await db.delete(tableQuotes);
    total += await db.delete(tableNotes);
    total += await db.delete(tableHighlights);
    total += await db.delete(tableCollections);
    total += await db.delete(tableBooks);
    return total;
  }

  /// Executes a raw SQL query and returns the raw results.
  /// Useful for custom queries not covered by the helper methods.
  Future<List<Map<String, dynamic>>> rawQuery(
      String sql, [List<Object?>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args ?? []);
  }

  /// Returns the count of books in the library.
  Future<int> getBookCount() async {
    final db = await database;
    final results =
        await db.rawQuery('SELECT COUNT(*) as count FROM $tableBooks');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  /// Returns the count of books by [ReadingStatus].
  Future<int> getBookCountByStatus(ReadingStatus status) async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableBooks WHERE reading_status = ?',
      [status.name],
    );
    return Sqflite.firstIntValue(results) ?? 0;
  }
}
