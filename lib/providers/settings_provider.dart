/// Settings provider for the Libora reading ecosystem.
///
/// Manages all user preferences: app theme, reader appearance, reading goals,
/// storage, notifications, and file paths. Persisted via [SharedPreferences].
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The visual theme of the reader view.
enum ReaderTheme { light, sepia, dark, amoled }

/// Extension to convert [ReaderTheme] to/from string.
extension ReaderThemeX on ReaderTheme {
  String get name {
    switch (this) {
      case ReaderTheme.light:
        return 'light';
      case ReaderTheme.sepia:
        return 'sepia';
      case ReaderTheme.dark:
        return 'dark';
      case ReaderTheme.amoled:
        return 'amoled';
    }
  }

  static ReaderTheme fromString(String? value) {
    switch (value) {
      case 'sepia':
        return ReaderTheme.sepia;
      case 'dark':
        return ReaderTheme.dark;
      case 'amoled':
        return ReaderTheme.amoled;
      default:
        return ReaderTheme.light;
    }
  }
}

/// How text is aligned in the reader.
enum ReaderTextAlignment { left, justify, center }

extension ReaderTextAlignmentX on ReaderTextAlignment {
  String get name {
    switch (this) {
      case ReaderTextAlignment.left:
        return 'left';
      case ReaderTextAlignment.justify:
        return 'justify';
      case ReaderTextAlignment.center:
        return 'center';
    }
  }

  static ReaderTextAlignment fromString(String? value) {
    switch (value) {
      case 'justify':
        return ReaderTextAlignment.justify;
      case 'center':
        return ReaderTextAlignment.center;
      default:
        return ReaderTextAlignment.left;
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  // ── App theme ──
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // ── Reader theme ──
  ReaderTheme _readerTheme = ReaderTheme.light;
  ReaderTheme get readerTheme => _readerTheme;

  // ── Reader typography ──
  double _fontSize = 18.0;
  double get fontSize => _fontSize;

  String _fontFamily = 'Serif';
  String get fontFamily => _fontFamily;

  double _lineSpacing = 1.5;
  double get lineSpacing => _lineSpacing;

  double _margins = 16.0;
  double get margins => _margins;

  ReaderTextAlignment _textAlignment = ReaderTextAlignment.justify;
  ReaderTextAlignment get textAlignment => _textAlignment;

  // ── Reading goal ──
  int _readingGoal = 12;
  int get readingGoal => _readingGoal;

  // ── Storage ──
  String _downloadPath = '';
  String get downloadPath => _downloadPath;

  int _storageLimitMB = 500;
  int get storageLimitMB => _storageLimitMB;

  String _importPath = '';
  String get importPath => _importPath;

  // ── Notifications ──
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  // ── Init state ──
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Loads all settings from SharedPreferences. Must be called once at startup.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    _themeMode = _themeModeFromString(_prefs!.getString('themeMode'));
    _readerTheme =
        ReaderThemeX.fromString(_prefs!.getString('readerTheme'));
    _fontSize = _prefs!.getDouble('fontSize') ?? 18.0;
    _fontFamily = _prefs!.getString('fontFamily') ?? 'Serif';
    _lineSpacing = _prefs!.getDouble('lineSpacing') ?? 1.5;
    _margins = _prefs!.getDouble('margins') ?? 16.0;
    _textAlignment = ReaderTextAlignmentX.fromString(
        _prefs!.getString('textAlignment'));
    _readingGoal = _prefs!.getInt('readingGoal') ?? 12;
    _downloadPath = _prefs!.getString('downloadPath') ?? '';
    _storageLimitMB = _prefs!.getInt('storageLimitMB') ?? 500;
    _importPath = _prefs!.getString('importPath') ?? '';
    _notificationsEnabled =
        _prefs!.getBool('notificationsEnabled') ?? true;

    _isInitialized = true;
    notifyListeners();
  }

  // ── Theme mode ──

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setString('themeMode', _themeModeToString(mode));
    notifyListeners();
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // ── Reader theme ──

  Future<void> setReaderTheme(ReaderTheme theme) async {
    _readerTheme = theme;
    await _prefs?.setString('readerTheme', theme.name);
    notifyListeners();
  }

  // ── Font size ──

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    await _prefs?.setDouble('fontSize', size);
    notifyListeners();
  }

  // ── Font family ──

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    await _prefs?.setString('fontFamily', family);
    notifyListeners();
  }

  // ── Line spacing ──

  Future<void> setLineSpacing(double spacing) async {
    _lineSpacing = spacing;
    await _prefs?.setDouble('lineSpacing', spacing);
    notifyListeners();
  }

  // ── Margins ──

  Future<void> setMargins(double margins) async {
    _margins = margins;
    await _prefs?.setDouble('margins', margins);
    notifyListeners();
  }

  // ── Text alignment ──

  Future<void> setTextAlignment(ReaderTextAlignment alignment) async {
    _textAlignment = alignment;
    await _prefs?.setString('textAlignment', alignment.name);
    notifyListeners();
  }

  // ── Reading goal ──

  Future<void> setReadingGoal(int goal) async {
    _readingGoal = goal;
    await _prefs?.setInt('readingGoal', goal);
    notifyListeners();
  }

  // ── Download path ──

  Future<void> setDownloadPath(String path) async {
    _downloadPath = path;
    await _prefs?.setString('downloadPath', path);
    notifyListeners();
  }

  // ── Storage limit ──

  Future<void> setStorageLimitMB(int limit) async {
    _storageLimitMB = limit;
    await _prefs?.setInt('storageLimitMB', limit);
    notifyListeners();
  }

  // ── Import path ──

  Future<void> setImportPath(String path) async {
    _importPath = path;
    await _prefs?.setString('importPath', path);
    notifyListeners();
  }

  // ── Notifications ──

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs?.setBool('notificationsEnabled', enabled);
    notifyListeners();
  }

  /// Resets all settings to their defaults.
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _readerTheme = ReaderTheme.light;
    _fontSize = 18.0;
    _fontFamily = 'Serif';
    _lineSpacing = 1.5;
    _margins = 16.0;
    _textAlignment = ReaderTextAlignment.justify;
    _readingGoal = 12;
    _storageLimitMB = 500;
    _notificationsEnabled = true;

    await _prefs?.remove('themeMode');
    await _prefs?.remove('readerTheme');
    await _prefs?.remove('fontSize');
    await _prefs?.remove('fontFamily');
    await _prefs?.remove('lineSpacing');
    await _prefs?.remove('margins');
    await _prefs?.remove('textAlignment');
    await _prefs?.remove('readingGoal');
    await _prefs?.remove('storageLimitMB');
    await _prefs?.remove('notificationsEnabled');

    notifyListeners();
  }
}
