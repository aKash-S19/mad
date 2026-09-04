/// Reader appearance settings bottom sheet for the Libora reader.
///
/// Contains theme selector (Light, Sepia, Dark, AMOLED), font size slider,
/// font family dropdown, line spacing slider, margins slider, and text
/// alignment toggle. Reads/writes via [SettingsProvider].
library;

import 'package:flutter/material.dart';
import 'package:libora/core/constants/app_constants.dart';
import 'package:libora/core/theme/reader_theme.dart' as rt;
import 'package:libora/providers/settings_provider.dart';

class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  /// Convenience method to show this sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ReaderSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Row(
              children: [
                Icon(Icons.tune, color: colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text('Reader Settings', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 24),

            // ── Theme selector ──
            _SectionHeader(title: 'Theme'),
            const SizedBox(height: 12),
            _ThemeSelector(settings: settings),
            const SizedBox(height: 28),

            // ── Font size ──
            _SectionHeader(title: 'Font Size'),
            const SizedBox(height: 8),
            _FontSizeControl(settings: settings),
            const SizedBox(height: 24),

            // ── Font family ──
            _SectionHeader(title: 'Font Family'),
            const SizedBox(height: 8),
            _FontFamilyControl(settings: settings),
            const SizedBox(height: 24),

            // ── Line spacing ──
            _SectionHeader(title: 'Line Spacing'),
            const SizedBox(height: 8),
            _LineSpacingControl(settings: settings),
            const SizedBox(height: 24),

            // ── Margins ──
            _SectionHeader(title: 'Margins'),
            const SizedBox(height: 8),
            _MarginsControl(settings: settings),
            const SizedBox(height: 24),

            // ── Text alignment ──
            _SectionHeader(title: 'Text Alignment'),
            const SizedBox(height: 8),
            _AlignmentControl(settings: settings),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Section header ──

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Theme selector ──

class _ThemeSelector extends StatelessWidget {
  final SettingsProvider settings;
  const _ThemeSelector({required this.settings});

  static const _options = [
    (ReaderTheme.light, rt.ReaderTheme.light, 'Light', Icons.light_mode),
    (ReaderTheme.sepia, rt.ReaderTheme.sepia, 'Sepia', Icons.auto_awesome),
    (ReaderTheme.dark, rt.ReaderTheme.dark, 'Dark', Icons.dark_mode),
    (ReaderTheme.amoled, rt.ReaderTheme.amoled, 'AMOLED', Icons.contrast),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final option = _options[index];
          final isSelected = settings.readerTheme == option.$1;
          final palette = option.$2;

          return GestureDetector(
            onTap: () => settings.setReaderTheme(option.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              decoration: BoxDecoration(
                color: palette.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    option.$4,
                    size: 20,
                    color: palette.textColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.$3,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Font size control ──

class _FontSizeControl extends StatelessWidget {
  final SettingsProvider settings;
  const _FontSizeControl({required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: settings.fontSize > AppConstants.minFontSize
              ? () => settings.setFontSize(
                  (settings.fontSize - 1).clamp(
                    AppConstants.minFontSize,
                    AppConstants.maxFontSize,
                  ),
                )
              : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: colorScheme.primary,
          iconSize: 28,
        ),
        Expanded(
          child: Slider(
            value: settings.fontSize,
            min: AppConstants.minFontSize,
            max: AppConstants.maxFontSize,
            divisions:
                (AppConstants.maxFontSize - AppConstants.minFontSize).round(),
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.primary.withValues(alpha: 0.2),
            label: settings.fontSize.round().toString(),
            onChanged: (v) => settings.setFontSize(v.roundToDouble()),
            onChangeEnd: (v) => settings.setFontSize(v.roundToDouble()),
          ),
        ),
        IconButton(
          onPressed: settings.fontSize < AppConstants.maxFontSize
              ? () => settings.setFontSize(
                  (settings.fontSize + 1).clamp(
                    AppConstants.minFontSize,
                    AppConstants.maxFontSize,
                  ),
                )
              : null,
          icon: const Icon(Icons.add_circle_outline),
          color: colorScheme.primary,
          iconSize: 28,
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${settings.fontSize.round()}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Font family control ──

class _FontFamilyControl extends StatelessWidget {
  final SettingsProvider settings;
  const _FontFamilyControl({required this.settings});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'Serif', label: Text('Serif')),
        ButtonSegment(value: 'Sans', label: Text('Sans')),
        ButtonSegment(value: 'Mono', label: Text('Mono')),
      ],
      selected: {settings.fontFamily},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          settings.setFontFamily(selection.first);
        }
      },
    );
  }
}

// ── Line spacing control ──

class _LineSpacingControl extends StatelessWidget {
  final SettingsProvider settings;
  const _LineSpacingControl({required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Text(
          'A',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Slider(
            value: settings.lineSpacing,
            min: AppConstants.minLineSpacing,
            max: AppConstants.maxLineSpacing,
            divisions:
                ((AppConstants.maxLineSpacing - AppConstants.minLineSpacing)
                        * 10)
                    .round(),
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.primary.withValues(alpha: 0.2),
            label: settings.lineSpacing.toStringAsFixed(1),
            onChanged: (v) => settings.setLineSpacing(
              double.parse(v.toStringAsFixed(1)),
            ),
          ),
        ),
        Text(
          'A',
          style: TextStyle(
            fontSize: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            settings.lineSpacing.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Margins control ──

class _MarginsControl extends StatelessWidget {
  final SettingsProvider settings;
  const _MarginsControl({required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Slider(
            value: settings.margins,
            min: 8,
            max: 48,
            divisions: 10,
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.primary.withValues(alpha: 0.2),
            label: _marginLabel(settings.margins),
            onChanged: (v) => settings.setMargins(v.roundToDouble()),
          ),
        ),
        SizedBox(
          width: 72,
          child: Text(
            _marginLabel(settings.margins),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _marginLabel(double margins) {
    if (margins <= 16) return 'Small';
    if (margins <= 28) return 'Medium';
    return 'Large';
  }
}

// ── Text alignment control ──

class _AlignmentControl extends StatelessWidget {
  final SettingsProvider settings;
  const _AlignmentControl({required this.settings});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ReaderTextAlignment>(
      segments: const [
        ButtonSegment(
          value: ReaderTextAlignment.left,
          icon: Icon(Icons.format_align_left),
          label: Text('Left'),
        ),
        ButtonSegment(
          value: ReaderTextAlignment.justify,
          icon: Icon(Icons.format_align_justify),
          label: Text('Justify'),
        ),
        ButtonSegment(
          value: ReaderTextAlignment.center,
          icon: Icon(Icons.format_align_center),
          label: Text('Center'),
        ),
      ],
      selected: {settings.textAlignment},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          settings.setTextAlignment(selection.first);
        }
      },
    );
  }
}
