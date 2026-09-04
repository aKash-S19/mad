/// Input validators and small text helpers for Libora.
///
/// Used by auth forms, file-import flows, and anywhere user-provided
/// strings need to be checked or cleaned before storage.
library;

class Validators {
  Validators._();

  // A pragmatic email pattern — not RFC-strict but good enough for UX.
  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );

  /// True if [email] is a syntactically valid email address.
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// True if [password] meets Libora's minimum password policy
  /// (at least 6 characters). Returns false for empty passwords.
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Strips characters that are illegal or dangerous in a file name on
  /// Windows/macOS/Linux: `\ / : * ? " < > |` and control chars.
  /// Collapses runs of whitespace into single spaces and trims ends.
  static String sanitizeFilename(String name) {
    if (name.isEmpty) return 'untitled';
    // Remove control characters.
    var cleaned = name.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '');
    // Replace illegal characters with underscore.
    cleaned = cleaned.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    // Collapse whitespace.
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Guard against reserved Windows names / dot-only names.
    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') {
      return 'untitled';
    }
    // Trim trailing dots/spaces (Windows quirk).
    cleaned = cleaned.replaceAll(RegExp(r'[. ]+$'), '');
    return cleaned.isEmpty ? 'untitled' : cleaned;
  }

  /// Truncates [text] to [maxChars] characters, appending an ellipsis
  /// ("…") only when truncation actually occurs. The returned string
  /// is never longer than `maxChars` (including the ellipsis).
  static String truncateText(String text, int maxChars) {
    if (maxChars <= 0) return '';
    if (text.length <= maxChars) return text;
    if (maxChars <= 1) return '…';
    return '${text.substring(0, maxChars - 1)}…';
  }

  /// Returns null if [email] is valid, otherwise an error message
  /// suitable for a [TextFormField] validator.
  static String? emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!isValidEmail(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Returns null if [password] is valid, otherwise an error message.
  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (!isValidPassword(value)) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) => emailValidator(value);

  static String? validatePassword(String? value) => passwordValidator(value);

  static String? validateName(String? value) =>
      requiredValidator(value, fieldName: 'Name');

  /// Returns null if [value] is non-empty after trimming.
  static String? requiredValidator(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
