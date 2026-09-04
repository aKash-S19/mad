/// File-system utilities for Libora.
///
/// Provides path helpers, format detection, human-readable file sizes,
/// and UUID-based book ID generation. The [uuid] package is used for
/// stable, collision-resistant IDs across imports and downloads.
library;

import 'package:uuid/uuid.dart';

class FileUtils {
  FileUtils._();

  static const _uuid = Uuid();

  /// Returns the lowercase file extension (without the dot) for [path].
  /// Returns an empty string if there is no extension.
  static String getFileExtension(String path) {
    // Normalise path separators so Windows-style paths also parse cleanly.
    final normalised = path.replaceAll('\\', '/');
    final dot = normalised.lastIndexOf('.');
    if (dot < 0 || dot == normalised.length - 1) return '';
    // Strip any query string a remote URL might carry.
    final ext = normalised.substring(dot + 1).split('?').first;
    return ext.toLowerCase();
  }

  /// True if [path] points to a PDF file (by extension).
  static bool isPdf(String path) => getFileExtension(path) == 'pdf';

  /// True if [path] points to an EPUB file (by extension).
  static bool isEpub(String path) {
    final ext = getFileExtension(path);
    return ext == 'epub' || ext == 'epub3';
  }

  /// True if [path] points to a plain-text file Libora can import.
  static bool isText(String path) {
    switch (getFileExtension(path)) {
      case 'txt':
      case 'md':
      case 'markdown':
        return true;
      default:
        return false;
    }
  }

  /// Returns just the file name (with extension) from [path],
  /// handling both `/` and `\` separators.
  static String getFileName(String path) {
    final normalised = path.replaceAll('\\', '/');
    final slash = normalised.lastIndexOf('/');
    if (slash < 0) return normalised;
    return normalised.substring(slash + 1);
  }

  /// Returns the file name without its extension.
  static String getFileNameWithoutExtension(String path) {
    final name = getFileName(path);
    final dot = name.lastIndexOf('.');
    if (dot <= 0) return name; // hidden files keep the dot
    return name.substring(0, dot);
  }

  /// Human-readable file size from a byte count.
  /// Examples: `formatFileSize(0)` → "0 B";
  /// `formatFileSize(13000000)` → "12.4 MB".
  static String formatFileSize(int bytes) {
    if (bytes < 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    if (unit == 0) {
      return '${size.toInt()} ${units[unit]}';
    }
    return '${size.toStringAsFixed(1)} ${units[unit]}';
  }

  /// Generates a new unique book ID using a v4 UUID.
  /// Returned without braces, e.g. `a1b2c3d4-...`.
  static String generateBookId() => _uuid.v4();

  /// Generates a short, sortable ID (UUID v1 with timestamp prefix).
  /// Useful for highlights/notes where creation order matters.
  static String generateSortableId() => _uuid.v1();

  /// Returns the relative path (under the app's library folder) where
  /// a book's cover image should be stored.
  static String getCoverPath(String bookId, [String? extension]) {
    final ext = (extension ?? 'png').replaceFirst('.', '');
    return 'Covers/$bookId.$ext';
  }

  /// Returns the relative path where a book file should be stored,
  /// preserving its original format.
  static String getBookFilePath(String bookId, String format) {
    final ext = format.replaceFirst('.', '').toLowerCase();
    return 'Books/$bookId.$ext';
  }

  /// Builds a safe storage path for a generic asset under the library
  /// folder. [folder] is a sub-folder name like "Highlights" or "Notes".
  static String getAssetPath(String folder, String fileName) {
    return '$folder/$fileName';
  }
}
