/// Reader-specific color tokens for Libora.
///
/// The [ReaderTheme] enum is defined in `SettingsProvider` (see
/// `lib/providers/settings_provider.dart`). This file provides a companion
/// [ReaderThemeColors] bundle — a plain value object holding the concrete
/// colors for each reader palette — plus static getters to resolve them by
/// theme name (`light`, `sepia`, `dark`, `amoled`).
///
/// Each palette exposes: backgroundColor, textColor, accentColor, cardColor,
/// appBarColor — enough to theme the reader view, its chrome, and any cards
/// overlaid on the page (notes, highlights picker, etc.).
library;

import 'package:flutter/material.dart';

/// A bundle of concrete colors for one reader palette.
@immutable
class ReaderThemeColors {
  const ReaderThemeColors({
    required this.name,
    required this.brightness,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.cardColor,
    required this.appBarColor,
    this.highlightColors = const [
      Color(0xFFFFEB3B), // yellow
      Color(0xFFFF9800), // orange
      Color(0xFF4CAF50), // green
      Color(0xFF2196F3), // blue
      Color(0xFFE91E63), // pink
      Color(0xFFAB47BC), // purple
    ],
  });

  /// The palette key — one of: `light`, `sepia`, `dark`, `amoled`.
  final String name;

  /// Whether this palette is dark (governs contrast adjustments elsewhere).
  final Brightness brightness;

  /// The page background behind the running text.
  final Color backgroundColor;

  /// The main body text color.
  final Color textColor;

  /// Accent color — links, active controls, selection underline.
  final Color accentColor;

  /// Card / elevated surface color (note popups, toolbars).
  final Color cardColor;

  /// AppBar / top chrome background.
  final Color appBarColor;

  /// Default highlight palette available in this reader theme.
  final List<Color> highlightColors;

  /// True when this is a dark or AMOLED palette.
  bool get isDark => brightness == Brightness.dark;

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is ReaderThemeColors &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() =>
      'ReaderThemeColors($name: bg=$backgroundColor, text=$textColor, accent=$accentColor)';
}

/// Static access to reader palettes and a [forName] resolver.
class ReaderTheme {
  ReaderTheme._();

  /// All supported palette names, in display order.
  static const List<String> names = ['light', 'sepia', 'dark', 'amoled'];

  // ── Light ──────────────────────────────────────────────────────
  // Clean paper-white page, near-black text for crisp readability.
  static const ReaderThemeColors light = ReaderThemeColors(
    name: 'light',
    brightness: Brightness.light,
    backgroundColor: Color(0xFFFBFBFB),
    textColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFF00695C),
    cardColor: Color(0xFFFFFFFF),
    appBarColor: Color(0xFFFBFBFB),
  );

  // ── Sepia ─────────────────────────────────────────────────────
  // Warm cream background (#F4EDE0) with dark brown text — easy on the eyes.
  static const ReaderThemeColors sepia = ReaderThemeColors(
    name: 'sepia',
    brightness: Brightness.light,
    backgroundColor: Color(0xFFF4EDE0),
    textColor: Color(0xFF3E2723),
    accentColor: Color(0xFF8D6E63),
    cardColor: Color(0xFFFAF3E6),
    appBarColor: Color(0xFFEFE6D3),
  );

  // ── Dark ───────────────────────────────────────────────────────
  // Deep charcoal background, soft white text.
  static const ReaderThemeColors dark = ReaderThemeColors(
    name: 'dark',
    brightness: Brightness.dark,
    backgroundColor: Color(0xFF121212),
    textColor: Color(0xFFE0E0E0),
    accentColor: Color(0xFF4DB6AC),
    cardColor: Color(0xFF1E1E1E),
    appBarColor: Color(0xFF121212),
  );

  // ── AMOLED ──────────────────────────────────────────────────────
  // Pure black (#000000) background with light gray text — true OLED dark.
  static const ReaderThemeColors amoled = ReaderThemeColors(
    name: 'amoled',
    brightness: Brightness.dark,
    backgroundColor: Color(0xFF000000),
    textColor: Color(0xFFBDBDBD),
    accentColor: Color(0xFF4DB6AC),
    cardColor: Color(0xFF0A0A0A),
    appBarColor: Color(0xFF000000),
  );

  /// Returns the [ReaderThemeColors] for a palette [name].
  ///
  /// [name] is case-insensitive. Falls back to [light] for unknown values.
  static ReaderThemeColors forName(String? name) {
    if (name == null) return light;
    switch (name.toLowerCase()) {
      case 'light':
        return light;
      case 'sepia':
        return sepia;
      case 'dark':
        return dark;
      case 'amoled':
        return amoled;
      default:
        return light;
    }
  }

  /// Convenience: returns the palette colors by index (0–3).
  static ReaderThemeColors byIndex(int index) {
    const all = [light, sepia, dark, amoled];
    return all[((index % all.length) + all.length) % all.length];
  }

  /// Human-readable display label for a palette name.
  static String labelFor(String name) {
    switch (name.toLowerCase()) {
      case 'light':
        return 'Light';
      case 'sepia':
        return 'Sepia';
      case 'dark':
        return 'Dark';
      case 'amoled':
        return 'AMOLED';
      default:
        return 'Light';
    }
  }
}
