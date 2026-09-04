/// Static configuration constants for the Libora app.
///
/// Centralises version numbers, database/prefs keys, reader defaults,
/// highlight colors, external API base URLs, share templates, and
/// storage folder names — all in one place.
library;

class AppConstants {
  AppConstants._();

  // ── App identity ──────────────────────────────────────────────
  static const String appName = 'Libora';
  static const String appVersion = '1.0.0';
  static const int appVersionCode = 1; // build number for migrations

  // ── Database ───────────────────────────────────────────────────
  static const int dbVersion = 1;
  static const String dbName = 'libora.db';

  // ── SharedPreferences root key ────────────────────────────────
  static const String sharedPrefsKey = 'libora_prefs';

  // ── Reading goal (books per year) ──────────────────────────────
  static const int defaultReadingGoal = 12;

  // ── Reader typography bounds ───────────────────────────────────
  static const double maxFontSize = 28.0;
  static const double minFontSize = 12.0;
  static const double defaultFontSize = 16.0;

  static const double maxLineSpacing = 2.5;
  static const double minLineSpacing = 1.0;
  static const double defaultLineSpacing = 1.5;

  // ── Highlight color palette (hex strings, no leading #) ───────
  // Kept as hex strings so they can be persisted in DB rows; resolve to
  // int via `int.parse('0xFF$hex')` at runtime.
  static const List<String> highlightColors = [
    'FFEB3B', // yellow
    'FF9800', // orange
    '4CAF50', // green
    '2196F3', // blue
    'E91E63', // pink
    'AB47BC', // purple
  ];

  // ── External catalog base URLs ──────────────────────────────────
  static const String openLibraryBaseUrl = 'https://openlibrary.org';
  static const String openLibrarySearchUrl =
      'https://openlibrary.org/search.json';
  static const String gutenbergBaseUrl = 'https://gutenberg.org';
  static const String gutenbergSearchUrl =
      'https://gnikd4epod.execute-api.us-east-1.amazonaws.com/gutenberg/search';
  static const String internetArchiveBaseUrl = 'https://archive.org';
  static const String internetArchiveSearchUrl =
      'https://archive.org/advancedsearch.php';

  // ── Share template ─────────────────────────────────────────────
  // Placeholders: {quote}, {bookTitle}, {author}, {appName}.
  static const String shareTextTemplate =
      '"{quote}"\n\n— {author}, {bookTitle}\n\nvia {appName}';

  // ── Storage ─────────────────────────────────────────────────────
  static const String libraryFolderName = 'Libora';
  static const String booksFolderName = 'Books';
  static const String coversFolderName = 'Covers';
  static const String importsFolderName = 'Imports';

  // ── HTTP / network ─────────────────────────────────────────────
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration networkConnectTimeout = Duration(seconds: 15);

  // ── Paging defaults ────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageLimit = 100;

  // ── UI ─────────────────────────────────────────────────────────
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration pageTransitionDuration = Duration(milliseconds: 250);
  static const Duration splashMinDisplay = Duration(seconds: 2);

  // ── Storage default cap ────────────────────────────────────────
  static const int defaultStorageLimitMB = 500;

  // ── Reader paging ──────────────────────────────────────────────
  static const int readerPreloadChapters = 1; // preload adjacent chapters

  // ── Built-in reader font families ──────────────────────────────
  static const List<String> readerFontFamilies = ['Serif', 'Sans', 'Mono'];

  // ── Quick stats reset window ─────────────────────────────────
  static const int readingStreakGraceDays = 1;

  /// Resolves a highlight hex string to a 0xAARRGGBB int.
  static int hexToInt(String hex) {
    final clean = hex.replaceFirst('#', '').toUpperCase();
    return int.parse('0xFF$clean');
  }
}
