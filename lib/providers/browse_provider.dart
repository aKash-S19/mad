/// Browse provider for the Libora reading ecosystem.
///
/// Manages book discovery from remote sources: Open Library and
/// Project Gutenberg. Supports searching, browsing trending titles,
/// categories, and fetching book details.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:libora/data/models/remote_book_model.dart';

/// The remote source to search.
enum BrowseSource { openLibrary, gutenberg, internetArchive, all }

class BrowseProvider extends ChangeNotifier {
  List<RemoteBook> _searchResults = [];
  List<RemoteBook> get searchResults => _searchResults;

  List<RemoteBook> _trendingBooks = [];
  List<RemoteBook> get trendingBooks => _trendingBooks;

  List<String> _categories = [];
  List<String> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  BrowseSource _selectedSource = BrowseSource.all;
  BrowseSource get selectedSource => _selectedSource;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  static const String _openLibrarySearchUrl =
      'https://openlibrary.org/search.json';
  static const String _openLibraryCoverUrl =
      'https://covers.openlibrary.org/b/id';
  static const String _gutenbergSearchUrl =
      'https://gutendex.com/books';

  /// Searches books across selected sources.
  Future<void> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _searchQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<RemoteBook> results = [];

      // Search Open Library (unless gutenberg-only)
      if (_selectedSource == BrowseSource.all ||
          _selectedSource == BrowseSource.openLibrary) {
        results.addAll(await _searchOpenLibrary(query));
      }

      // Search Project Gutenberg (unless openLibrary-only)
      if (_selectedSource == BrowseSource.all ||
          _selectedSource == BrowseSource.gutenberg) {
        results.addAll(await _searchGutenberg(query));
      }

      _searchResults = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Search failed: $e';
      debugPrint('BrowseProvider: searchBooks error: $e');
      notifyListeners();
    }
  }

  /// Searches the Open Library API.
  Future<List<RemoteBook>> _searchOpenLibrary(String query) async {
    try {
      final uri = Uri.parse(_openLibrarySearchUrl).replace(
        queryParameters: {
          'q': query,
          'limit': '20',
        },
      );
      final response = await http.get(uri);

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final docs = data['docs'] as List? ?? [];

      return docs.map<RemoteBook>((doc) {
        final coverId = doc['cover_i'];
        final coverUrl = coverId != null
            ? '$_openLibraryCoverUrl/$coverId-M.jpg'
            : null;

        // Build download URL if available
        final ia = doc['ia'] as List?;
        String? downloadUrl;
        if (ia != null && ia.isNotEmpty) {
          downloadUrl =
              'https://archive.org/download/${ia.first}/${ia.first}.pdf';
        }

        final authorList = doc['author_name'] as List?;
        final author =
            authorList != null && authorList.isNotEmpty ? authorList.first : '';

        final subjectList = doc['subject'] as List?;
        final subjects = subjectList != null
            ? subjectList.map((e) => e.toString()).toList()
            : <String>[];

        final publishYear = doc['first_publish_year'];

        return RemoteBook(
          id: doc['key']?.toString() ?? doc['cover_i']?.toString() ?? '',
          title: doc['title']?.toString() ?? 'Unknown Title',
          author: author,
          description: '',
          coverUrl: coverUrl,
          downloadUrl: downloadUrl,
          fileType: 'pdf',
          source: RemoteBookSource.openLibrary,
          publishYear: publishYear is int ? publishYear : null,
          language: doc['language']?.toString(),
          subjects: subjects,
          isbn: doc['isbn'] is List && (doc['isbn'] as List).isNotEmpty
              ? (doc['isbn'] as List).first.toString()
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('BrowseProvider: _searchOpenLibrary error: $e');
      return [];
    }
  }

  /// Searches the Project Gutenberg API (Gutendex).
  Future<List<RemoteBook>> _searchGutenberg(String query) async {
    try {
      final uri = Uri.parse(_gutenbergSearchUrl).replace(
        queryParameters: {'search': query},
      );
      final response = await http.get(uri);

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final books = data['results'] as List? ?? [];

      return books.map<RemoteBook>((book) {
        final authors = book['authors'] as List? ?? [];
        final author = authors.isNotEmpty
            ? (authors.first['name']?.toString() ?? '')
            : '';

        final subjects = book['subjects'] as List? ?? [];
        final subjectList = subjects
            .expand((s) => [s.toString()])
            .toList();

        // Get download URL for epub format
        final formats = book['formats'] as Map? ?? {};
        String? downloadUrl;
        String fileType = 'pdf';

        // Look for epub first, then pdf
        for (final entry in formats.entries) {
          final key = entry.key.toString().toLowerCase();
          if (key.contains('epub')) {
            downloadUrl = entry.value.toString();
            fileType = 'epub';
            break;
          }
        }
        if (downloadUrl == null) {
          for (final entry in formats.entries) {
            final key = entry.key.toString().toLowerCase();
            if (key.contains('pdf')) {
              downloadUrl = entry.value.toString();
              fileType = 'pdf';
              break;
            }
          }
        }

        final coverUrl = book['formats']?['image/jpeg']?.toString();

        return RemoteBook(
          id: book['id']?.toString() ?? '',
          title: book['title']?.toString() ?? 'Unknown Title',
          author: author,
          description: '',
          coverUrl: coverUrl,
          downloadUrl: downloadUrl,
          fileType: fileType,
          source: RemoteBookSource.gutenberg,
          subjects: subjectList,
        );
      }).toList();
    } catch (e) {
      debugPrint('BrowseProvider: _searchGutenberg error: $e');
      return [];
    }
  }

  /// Fetches trending/popular books.
  Future<void> getTrending() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Gutenberg trending (popular by downloads)
      final uri = Uri.parse(_gutenbergSearchUrl).replace(
        queryParameters: {'sort': 'popular'},
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data =
            json.decode(response.body) as Map<String, dynamic>;
        final books = data['results'] as List? ?? [];

        _trendingBooks = books.map<RemoteBook>((book) {
          final authors = book['authors'] as List? ?? [];
          final author = authors.isNotEmpty
              ? (authors.first['name']?.toString() ?? '')
              : '';

          final formats = book['formats'] as Map? ?? {};
          String? downloadUrl;
          String fileType = 'pdf';
          for (final entry in formats.entries) {
            final key = entry.key.toString().toLowerCase();
            if (key.contains('epub')) {
              downloadUrl = entry.value.toString();
              fileType = 'epub';
              break;
            }
          }
          if (downloadUrl == null) {
            for (final entry in formats.entries) {
              final key = entry.key.toString().toLowerCase();
              if (key.contains('pdf')) {
                downloadUrl = entry.value.toString();
                fileType = 'pdf';
                break;
              }
            }
          }

          final coverUrl =
              book['formats']?['image/jpeg']?.toString();

          return RemoteBook(
            id: book['id']?.toString() ?? '',
            title: book['title']?.toString() ?? 'Unknown',
            author: author,
            coverUrl: coverUrl,
            downloadUrl: downloadUrl,
            fileType: fileType,
            source: RemoteBookSource.gutenberg,
          );
        }).toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load trending: $e';
      debugPrint('BrowseProvider: getTrending error: $e');
      notifyListeners();
    }
  }

  /// Fetches available categories/subjects.
  Future<void> getCategories() async {
    try {
      final uri = Uri.parse('$_gutenbergSearchUrl/bookshelves');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data =
            json.decode(response.body) as Map<String, dynamic>;
        final shelves = data['results'] as List? ?? [];
        _categories = shelves
            .map((s) => s['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load categories: $e';
      debugPrint('BrowseProvider: getCategories error: $e');
      notifyListeners();
    }
  }

  /// Gets detailed information about a specific remote book.
  Future<RemoteBook?> getBookDetails(
      String id, RemoteBookSource source) async {
    try {
      if (source == RemoteBookSource.openLibrary) {
        final uri =
            Uri.parse('https://openlibrary.org/works/$id.json');
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data =
              json.decode(response.body) as Map<String, dynamic>;
          final desc = data['description'];
          final description = desc is String
              ? desc
              : desc is Map
                  ? desc['value']?.toString() ?? ''
                  : '';

          return RemoteBook(
            id: id,
            title: data['title']?.toString() ?? '',
            author: '',
            description: description,
            source: RemoteBookSource.openLibrary,
          );
        }
      } else if (source == RemoteBookSource.gutenberg) {
        final uri = Uri.parse('$_gutenbergSearchUrl/$id');
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data =
              json.decode(response.body) as Map<String, dynamic>;
          final authors = data['authors'] as List? ?? [];
          final author = authors.isNotEmpty
              ? (authors.first['name']?.toString() ?? '')
              : '';

          final formats = data['formats'] as Map? ?? {};
          String? downloadUrl;
          String fileType = 'pdf';
          for (final entry in formats.entries) {
            final key = entry.key.toString().toLowerCase();
            if (key.contains('epub')) {
              downloadUrl = entry.value.toString();
              fileType = 'epub';
              break;
            }
          }

          return RemoteBook(
            id: id,
            title: data['title']?.toString() ?? '',
            author: author,
            description: '',
            downloadUrl: downloadUrl,
            fileType: fileType,
            source: RemoteBookSource.gutenberg,
            coverUrl:
                data['formats']?['image/jpeg']?.toString(),
          );
        }
      }
    } catch (e) {
      _error = 'Failed to get book details: $e';
      debugPrint('BrowseProvider: getBookDetails error: $e');
      notifyListeners();
    }
    return null;
  }

  /// Sets the selected source.
  void setSource(BrowseSource source) {
    _selectedSource = source;
    notifyListeners();
  }

  /// Clears search results.
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
