/// Application theme definitions for Libora.
///
/// Defines the light and dark [ThemeData] for the app using Material 3,
/// plus static reader-specific [ColorScheme]s for the in-book reading view
/// (light, sepia, dark, AMOLED).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised app theme configuration.
///
/// Usage in [MaterialApp]:
/// ```dart
/// theme: AppTheme.lightTheme,
/// darkTheme: AppTheme.darkTheme,
/// themeMode: settings.themeMode,
/// ```
class AppTheme {
  AppTheme._();

  // ── Brand palette ──────────────────────────────────────────────

  /// Sophisticated dark teal used as the app's primary brand color.
  static const Color _primaryLight = Color(0xFF00695C);
  static const Color _primaryDark = Color(0xFF4DB6AC);

  /// Warm cream/sand background tones for a library feel.
  static const Color _warmBgLight = Color(0xFFFAF6F0);
  static const Color _warmSurfaceLight = Color(0xFFFFFFFF);
  static const Color _warmBgDark = Color(0xFF121416);
  static const Color _warmSurfaceDark = Color(0xFF1B1E21);

  /// Secondary accent — a warm amber for highlights/CTA emphasis.
  static const Color _accentAmber = Color(0xFFFFB74B);
  static const Color _accentAmberDark = Color(0xFFFFCC80);

  // ── Light theme ────────────────────────────────────────────────

  static ThemeData get lightTheme => _buildLightTheme();
  static ThemeData get darkTheme => _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryLight,
      primary: _primaryLight,
      secondary: _accentAmber,
      surface: _warmSurfaceLight,
      surfaceContainerHighest: const Color(0xFFF3EDE6),
      onSurface: const Color(0xFF1C1B1F),
      onSurfaceVariant: const Color(0xFF49454F),
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      brightness: Brightness.light,
    );

    return _buildBaseTheme(colorScheme, Brightness.light);
  }

  static ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryDark,
      primary: _primaryDark,
      secondary: _accentAmberDark,
      surface: _warmSurfaceDark,
      surfaceContainerHighest: const Color(0xFF2A2D31),
      onSurface: const Color(0xFFE6E1E5),
      onSurfaceVariant: const Color(0xFFCAC4D0),
      error: const Color(0xFFF2B8B5),
      onError: const Color(0xFF601410),
      brightness: Brightness.dark,
    );

    return _buildBaseTheme(colorScheme, Brightness.dark);
  }

  static ThemeData _buildBaseTheme(ColorScheme scheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final textTheme = GoogleFonts.latoTextTheme(
      isLight ? Typography.blackCupertino : Typography.whiteCupertino,
    ).copyWith(
      displayLarge: GoogleFonts.lora(
        textStyle: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          height: 1.12,
        ),
      ),
      displayMedium: GoogleFonts.lora(
        textStyle: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          height: 1.15,
        ),
      ),
      displaySmall: GoogleFonts.lora(
        textStyle: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          height: 1.2,
        ),
      ),
      headlineLarge: GoogleFonts.lora(
        textStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          height: 1.25,
        ),
      ),
      headlineMedium: GoogleFonts.lora(
        textStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
          height: 1.29,
        ),
      ),
      headlineSmall: GoogleFonts.lora(
        textStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
          height: 1.33,
        ),
      ),
      titleLarge: GoogleFonts.lato(
        textStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          height: 1.27,
        ),
      ),
      titleMedium: GoogleFonts.lato(
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          height: 1.5,
          letterSpacing: 0.15,
        ),
      ),
      titleSmall: GoogleFonts.lato(
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          height: 1.43,
          letterSpacing: 0.1,
        ),
      ),
      bodyLarge: GoogleFonts.lato(
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: scheme.onSurface,
          height: 1.5,
          letterSpacing: 0.15,
        ),
      ),
      bodyMedium: GoogleFonts.lato(
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: scheme.onSurfaceVariant,
          height: 1.43,
          letterSpacing: 0.25,
        ),
      ),
      bodySmall: GoogleFonts.lato(
        textStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: scheme.onSurfaceVariant,
          height: 1.33,
          letterSpacing: 0.4,
        ),
      ),
      labelLarge: GoogleFonts.lato(
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onPrimary,
          height: 1.43,
          letterSpacing: 0.1,
        ),
      ),
      labelMedium: GoogleFonts.lato(
        textStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
          height: 1.33,
          letterSpacing: 0.5,
        ),
      ),
      labelSmall: GoogleFonts.lato(
        textStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
          height: 1.45,
          letterSpacing: 0.5,
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface.withValues(alpha: 0.0),
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        shadowColor: scheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Bottom navigation bar ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            size: selected ? 26 : 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),

      // ── Input decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        prefixStyle: TextStyle(color: scheme.onSurfaceVariant),
        suffixStyle: TextStyle(color: scheme.onSurfaceVariant),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.outlineVariant,
            width: 1,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.error,
            width: 2,
          ),
        ),
      ),

      // ── Buttons ──
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(double.infinity, 52),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.primary.withValues(alpha: 0.3);
            }
            return scheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onPrimary.withValues(alpha: 0.5);
            }
            return scheme.onPrimary;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return scheme.onPrimary.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(double.infinity, 48),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevation: const WidgetStatePropertyAll(0),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(double.infinity, 48),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.disabled)
                ? scheme.outlineVariant.withValues(alpha: 0.5)
                : scheme.primary;
            return BorderSide(color: color, width: 1.5);
          }),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          iconSize: const WidgetStatePropertyAll(24),
        ),
      ),

      // ── List tile ──
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: textTheme.bodyMedium,
        iconColor: scheme.onSurfaceVariant,
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),

      // ── Snackbar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(
          color: scheme.outlineVariant,
          width: 0.5,
        ),
      ),

      // ── Floating action button ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 3,
        disabledElevation: 0,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Progress indicators ──
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.12),
        circularTrackColor: scheme.primary.withValues(alpha: 0.12),
        linearMinHeight: 4,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // ── Bottom sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        modalBackgroundColor: scheme.surface,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
      ),

      // ── Slider ──
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.2),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: scheme.primary,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimary,
        ),
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: _tooltipTextStyle(scheme, textTheme),
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(seconds: 2),
      ),

      // ── Tab bar ──
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.titleSmall,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: scheme.primary, width: 2.5),
          insets: const EdgeInsets.symmetric(horizontal: 0),
        ),
        dividerColor: scheme.outlineVariant,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Scrollbar ──
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(scheme.outlineVariant.withValues(alpha: 0.6)),
        trackColor: WidgetStateProperty.all(scheme.surfaceContainerHighest),
        radius: const Radius.circular(4),
        thickness: const WidgetStatePropertyAll(6),
        thumbVisibility: const WidgetStatePropertyAll(false),
      ),
    );
  }

  // ── Reader-specific color schemes ──────────────────────────────
  //
  // These are used by the book reader view to switch between
  // reading-friendly palettes regardless of the app's overall theme.

  /// Reader — light theme. Clean white page, dark text.
  static ColorScheme get readerLight => const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF00695C),
        onPrimary: Colors.white,
        secondary: Color(0xFFFFB74B),
        onSecondary: Colors.black,
        error: Color(0xFFB3261E),
        onError: Colors.white,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1A1A1A),
        surfaceContainerHighest: Color(0xFFF0EFEA),
        onSurfaceVariant: Color(0xFF5A5A5A),
        outline: Color(0xFFBDBDBD),
        outlineVariant: Color(0xFFE0E0E0),
        primaryContainer: Color(0xFFB3E5DC),
        onPrimaryContainer: Color(0xFF003830),
        secondaryContainer: Color(0xFFFFE0B2),
        onSecondaryContainer: Color(0xFF3E2A00),
        inverseSurface: Color(0xFF2D2D2D),
        onInverseSurface: Color(0xFFF0F0F0),
        inversePrimary: Color(0xFF4DB6AC),
        surfaceTint: Color(0xFF00695C),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        tertiary: Color(0xFF795548),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFD7CCC8),
        onTertiaryContainer: Color(0xFF3E2723),
      );

  /// Reader — sepia theme. Warm cream background, dark brown text.
  static ColorScheme get readerSepia => const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF8D6E63),
        onPrimary: Colors.white,
        secondary: Color(0xFFFFB74B),
        onSecondary: Colors.black,
        error: Color(0xFFB3261E),
        onError: Colors.white,
        surface: Color(0xFFFAF3E6),
        onSurface: Color(0xFF3E2723),
        surfaceContainerHighest: Color(0xFFEBE0CC),
        onSurfaceVariant: Color(0xFF5D4037),
        outline: Color(0xFFA1887F),
        outlineVariant: Color(0xFFD7CCC8),
        primaryContainer: Color(0xFFD7CCC8),
        onPrimaryContainer: Color(0xFF3E2723),
        secondaryContainer: Color(0xFFFFE0B2),
        onSecondaryContainer: Color(0xFF3E2A00),
        inverseSurface: Color(0xFF4E342E),
        onInverseSurface: Color(0xFFF4EDE0),
        inversePrimary: Color(0xFF8D6E63),
        surfaceTint: Color(0xFF8D6E63),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        tertiary: Color(0xFF00695C),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFB3E5DC),
        onTertiaryContainer: Color(0xFF003830),
      );

  /// Reader — dark theme. Deep charcoal background, soft white text.
  static ColorScheme get readerDark => const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF4DB6AC),
        onPrimary: Color(0xFF003830),
        secondary: Color(0xFFFFCC80),
        onSecondary: Color(0xFF3E2A00),
        error: Color(0xFFF2B8B5),
        onError: Color(0xFF601410),
        surface: Color(0xFF1E1E1E),
        onSurface: Color(0xFFE0E0E0),
        surfaceContainerHighest: Color(0xFF2A2A2A),
        onSurfaceVariant: Color(0xFFB0B0B0),
        outline: Color(0xFF555555),
        outlineVariant: Color(0xFF333333),
        primaryContainer: Color(0xFF005047),
        onPrimaryContainer: Color(0xFFB3E5DC),
        secondaryContainer: Color(0xFF5D4037),
        onSecondaryContainer: Color(0xFFFFCC80),
        inverseSurface: Color(0xFFE0E0E0),
        onInverseSurface: Color(0xFF1A1A1A),
        inversePrimary: Color(0xFF00695C),
        surfaceTint: Color(0xFF4DB6AC),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        tertiary: Color(0xFF8D6E63),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF3E2723),
        onTertiaryContainer: Color(0xFFD7CCC8),
      );

  /// Reader — AMOLED. Pure black background, light gray text.
  static ColorScheme get readerAmoled => const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF4DB6AC),
        onPrimary: Color(0xFF003830),
        secondary: Color(0xFFFFCC80),
        onSecondary: Color(0xFF3E2A00),
        error: Color(0xFFF2B8B5),
        onError: Color(0xFF601410),
        surface: Color(0xFF0A0A0A),
        onSurface: Color(0xFFBDBDBD),
        surfaceContainerHighest: Color(0xFF1A1A1A),
        onSurfaceVariant: Color(0xFF9E9E9E),
        outline: Color(0xFF424242),
        outlineVariant: Color(0xFF1A1A1A),
        primaryContainer: Color(0xFF005047),
        onPrimaryContainer: Color(0xFFB3E5DC),
        secondaryContainer: Color(0xFF5D4037),
        onSecondaryContainer: Color(0xFFFFCC80),
        inverseSurface: Color(0xFFBDBDBD),
        onInverseSurface: Color(0xFF1A1A1A),
        inversePrimary: Color(0xFF00695C),
        surfaceTint: Color(0xFF4DB6AC),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        tertiary: Color(0xFF8D6E63),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF3E2723),
        onTertiaryContainer: Color(0xFFD7CCC8),
      );

  // Helper for tooltip text style before scheme is fully resolved.
  static TextStyle? _tooltipTextStyle(ColorScheme scheme, TextTheme textTheme) {
    return textTheme.labelMedium?.copyWith(color: scheme.onInverseSurface);
  }
}
