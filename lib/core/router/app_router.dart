/// Route configuration for the Libora app.
///
/// Defines all route names as static constants and provides a
/// [generateRoute] factory used by [MaterialApp.onGenerateRoute].
library;

import 'package:flutter/material.dart';

import 'package:libora/features/auth/login_screen.dart';
import 'package:libora/features/auth/signup_screen.dart';
import 'package:libora/features/book_details/book_details_screen.dart';
import 'package:libora/features/browse/browse_screen.dart';
import 'package:libora/features/collections/collection_details_screen.dart';
import 'package:libora/features/collections/collections_screen.dart';
import 'package:libora/features/download_manager/download_manager_screen.dart';
import 'package:libora/features/highlights/highlights_screen.dart';
import 'package:libora/features/home/home_screen.dart';
import 'package:libora/features/library/library_screen.dart';
import 'package:libora/features/notes/notes_screen.dart';
import 'package:libora/features/profile/profile_screen.dart';
import 'package:libora/features/quotes/quote_card_screen.dart';
import 'package:libora/features/quotes/quotes_screen.dart';
import 'package:libora/features/reader/reader_screen.dart';
import 'package:libora/features/search/search_screen.dart';
import 'package:libora/features/settings/settings_screen.dart';
import 'package:libora/features/splash/splash_screen.dart';
import 'package:libora/features/statistics/statistics_screen.dart';

class AppRouter {
  AppRouter._();

  // ── Route names ────────────────────────────────────────────────
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String library = '/library';
  static const String bookDetails = '/book-details';
  static const String reader = '/reader';
  static const String browse = '/browse';
  static const String search = '/search';
  static const String collections = '/collections';
  static const String collectionDetails = '/collection-details';
  static const String highlights = '/highlights';
  static const String notes = '/notes';
  static const String quotes = '/quotes';
  static const String quoteCard = '/quote-card';
  static const String profile = '/profile';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String downloadManager = '/download-manager';

  /// All routes keyed by name.
  static const Map<String, String> routeNames = {
    'splash': splash,
    'login': login,
    'signup': signup,
    'home': home,
    'library': library,
    'bookDetails': bookDetails,
    'reader': reader,
    'browse': browse,
    'search': search,
    'collections': collections,
    'collectionDetails': collectionDetails,
    'highlights': highlights,
    'notes': notes,
    'quotes': quotes,
    'quoteCard': quoteCard,
    'profile': profile,
    'statistics': statistics,
    'settings': settings,
    'downloadManager': downloadManager,
  };

  // ── Route factory ───────────────────────────────────────────────

  static MaterialPageRoute<dynamic> generateRoute(RouteSettings routeSettings) {
    final name = routeSettings.name ?? splash;
    final args = routeSettings.arguments;

    switch (name) {
      case splash:
        return _route(splash, const SplashScreen());
      case login:
        return _route(login, const LoginScreen());
      case signup:
        return _route(signup, const SignupScreen());
      case home:
        return _route(home, const HomeScreen());
      case library:
        return _route(library, const LibraryScreen());
      case bookDetails:
        final bookId = args is String
            ? args
            : (args is Map ? args['bookId']?.toString() ?? '' : '');
        return _route(bookDetails, BookDetailsScreen(bookId: bookId));
      case reader:
        final String bookId = args is String
            ? args
            : (args is Map ? args['bookId']?.toString() ?? '' : '');
        final int? chapterIndex =
            args is Map ? args['chapterIndex'] as int? : null;
        final int? page = args is Map ? args['page'] as int? : null;
        return _route(
          reader,
          ReaderScreen(
            bookId: bookId,
            initialChapterIndex: chapterIndex,
            initialPage: page,
          ),
        );
      case browse:
        return _route(browse, const BrowseScreen());
      case search:
        return _route(search, const SearchScreen());
      case collections:
        return _route(collections, const CollectionsScreen());
      case collectionDetails:
        final collectionId = args is String
            ? args
            : (args is Map ? args['collectionId']?.toString() ?? '' : '');
        return _route(
          collectionDetails,
          CollectionDetailsScreen(collectionId: collectionId),
        );
      case highlights:
        return _route(highlights, const HighlightsScreen());
      case notes:
        return _route(notes, const NotesScreen());
      case quotes:
        return _route(quotes, const QuotesScreen());
      case quoteCard:
        final quoteId = args is String
            ? args
            : (args is Map ? args['quoteId']?.toString() ?? '' : '');
        return _route(quoteCard, QuoteCardScreen(quoteId: quoteId));
      case profile:
        return _route(profile, const ProfileScreen());
      case statistics:
        return _route(statistics, const StatisticsScreen());
      case settings:
        return _route(settings, const SettingsScreen());
      case downloadManager:
        return _route(downloadManager, const DownloadManagerScreen());
      default:
        return _route(
          name,
          Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(child: Text('Route "$name" not found.')),
          ),
        );
    }
  }

  static MaterialPageRoute<dynamic> _route(String name, Widget child) {
    return MaterialPageRoute<dynamic>(
      settings: RouteSettings(name: name),
      builder: (_) => child,
    );
  }

  static Route<dynamic> readerRoute({
    required String bookId,
    int? chapterIndex,
    int? page,
  }) {
    return MaterialPageRoute<dynamic>(
      settings: RouteSettings(
        name: reader,
        arguments: {
          'bookId': bookId,
          if (chapterIndex != null) 'chapterIndex': chapterIndex,
          if (page != null) 'page': page,
        },
      ),
      builder: (_) => ReaderScreen(
        bookId: bookId,
        initialChapterIndex: chapterIndex,
        initialPage: page,
      ),
    );
  }

  static Route<dynamic> bookDetailsRoute(String bookId) {
    return MaterialPageRoute<dynamic>(
      settings: RouteSettings(name: bookDetails, arguments: bookId),
      builder: (_) => BookDetailsScreen(bookId: bookId),
    );
  }

  static Route<dynamic> collectionDetailsRoute(String collectionId) {
    return MaterialPageRoute<dynamic>(
      settings: RouteSettings(name: collectionDetails, arguments: collectionId),
      builder: (_) => CollectionDetailsScreen(collectionId: collectionId),
    );
  }
}
