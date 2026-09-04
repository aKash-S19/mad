import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database/database_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/library_provider.dart';
import 'providers/reader_provider.dart';
import 'providers/highlights_provider.dart';
import 'providers/quotes_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/collections_provider.dart';
import 'providers/browse_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/download_provider.dart';
import 'providers/search_provider.dart';
import 'providers/profile_provider.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase safely if configured
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not initialized (running in local-first offline mode): $e');
  }

  // Initialize local database
  await DatabaseHelper.instance.database;

  // Initialize SharedPreferences for settings
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => ReaderProvider()),
        ChangeNotifierProvider(create: (_) => HighlightsProvider()),
        ChangeNotifierProvider(create: (_) => QuotesProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => CollectionsProvider()),
        ChangeNotifierProvider(create: (_) => BrowseProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const LiboraApp(),
    ),
  );
}
