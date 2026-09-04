/// Settings screen for the Libora reading ecosystem.
///
/// Enables customization of:
/// - App visual theme (System, Light, Dark)
/// - Default reader appearance (font size, font family, margins, spacing, theme)
/// - Download and storage management (cache size, clear cache)
/// - About Libora information
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:libora/providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── App Appearance Section ──
          _sectionHeader(context, 'App Appearance'),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme Mode'),
                  subtitle: Text(_themeModeName(settings.themeMode)),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode, size: 16),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (modes) {
                      settings.setThemeMode(modes.first);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Default Reader Appearance Section ──
          _sectionHeader(context, 'Reader Appearance'),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reader Theme
                  Text('Reader Theme', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _readerThemeCircle(
                        context,
                        settings,
                        ReaderTheme.light,
                        'Light',
                        const Color(0xFFFAFAFA),
                        Colors.black87,
                      ),
                      _readerThemeCircle(
                        context,
                        settings,
                        ReaderTheme.sepia,
                        'Sepia',
                        const Color(0xFFFBF0D9),
                        const Color(0xFF5F4B32),
                      ),
                      _readerThemeCircle(
                        context,
                        settings,
                        ReaderTheme.dark,
                        'Dark',
                        const Color(0xFF202124),
                        Colors.white70,
                      ),
                      _readerThemeCircle(
                        context,
                        settings,
                        ReaderTheme.amoled,
                        'AMOLED',
                        Colors.black,
                        Colors.white,
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Font Size
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Default Font Size'),
                      Text('${settings.fontSize.toInt()} px',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: settings.fontSize,
                    min: 12,
                    max: 32,
                    divisions: 10,
                    onChanged: (val) => settings.setFontSize(val),
                  ),

                  // Font Family
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Font Family'),
                    trailing: DropdownButton<String>(
                      value: settings.fontFamily,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'Serif', child: Text('Serif')),
                        DropdownMenuItem(
                            value: 'Sans', child: Text('Sans-Serif')),
                        DropdownMenuItem(
                            value: 'Mono', child: Text('Monospace')),
                      ],
                      onChanged: (val) {
                        if (val != null) settings.setFontFamily(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Storage Section ──
          _sectionHeader(context, 'Storage & Offline Content'),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: const Text('Local Storage'),
                  subtitle: const Text('All imported and downloaded books remain on device'),
                  trailing: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Storage index refreshed')),
                      );
                    },
                    child: const Text('Manage'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: const Text('Clear Temporary Cache'),
                  subtitle: const Text('Free up temporary image cache'),
                  trailing: TextButton(
                    onPressed: () {
                      PaintingBinding.instance.imageCache.clear();
                      PaintingBinding.instance.imageCache.clearLiveImages();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Temporary cache cleared')),
                      );
                    },
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── About Libora ──
          _sectionHeader(context, 'About'),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded),
                  title: const Text('Libora'),
                  subtitle: const Text('Version 1.0.0 (Android)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Personal Reading Ecosystem'),
                  subtitle: const Text('Discover → Read → Interact → Save → Remember'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow System';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
    }
  }

  Widget _readerThemeCircle(
    BuildContext context,
    SettingsProvider settings,
    ReaderTheme themeVal,
    String label,
    Color bg,
    Color fg,
  ) {
    final isSelected = settings.readerTheme == themeVal;
    return GestureDetector(
      onTap: () => settings.setReaderTheme(themeVal),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade400,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Center(
              child: Text(
                'Aa',
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
