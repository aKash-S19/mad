/// Global Search screen for the Libora reading ecosystem.
///
/// Implements unified search across the user's personal reading content:
/// Books, Authors, Highlights, Quotes, Notes, and Collections.
/// Results are presented in organized, categorized sections with direct
/// deep-linking into the book reader at the exact passage.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:libora/core/router/app_router.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/collection_model.dart';
import 'package:libora/data/models/highlight_model.dart';
import 'package:libora/data/models/note_model.dart';
import 'package:libora/data/models/quote_model.dart';
import 'package:libora/providers/search_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    context.read<SearchProvider>().globalSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final search = context.watch<SearchProvider>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search books, quotes, notes, highlights...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: scheme.onSurfaceVariant),
          ),
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                search.globalSearch('');
              },
            ),
        ],
      ),
      body: search.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !search.hasSearched || _controller.text.trim().isEmpty
              ? _buildInitialState(scheme)
              : _buildResultsList(search, theme, scheme),
    );
  }

  Widget _buildInitialState(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: scheme.outline),
          const SizedBox(height: 16),
          Text(
            'Search your personal reading archive',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Books · Highlights · Quotes · Notes · Collections',
            style: TextStyle(color: scheme.outline, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(
      SearchProvider search, ThemeData theme, ColorScheme scheme) {
    final hasAny = search.books.isNotEmpty ||
        search.highlights.isNotEmpty ||
        search.quotes.isNotEmpty ||
        search.notes.isNotEmpty ||
        search.collections.isNotEmpty;

    if (!hasAny) {
      return Center(
        child: Text(
          'No results found for "${search.query}".',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // ── BOOKS ──
        if (search.books.isNotEmpty) ...[
          _sectionHeader('BOOKS (${search.books.length})', Icons.menu_book, scheme),
          ...search.books.map((b) => _buildBookTile(b, theme, scheme)),
          const SizedBox(height: 16),
        ],

        // ── HIGHLIGHTS ──
        if (search.highlights.isNotEmpty) ...[
          _sectionHeader('HIGHLIGHTS (${search.highlights.length})',
              Icons.highlight, scheme),
          ...search.highlights.map((h) => _buildHighlightTile(h, theme, scheme)),
          const SizedBox(height: 16),
        ],

        // ── QUOTES ──
        if (search.quotes.isNotEmpty) ...[
          _sectionHeader(
              'QUOTES (${search.quotes.length})', Icons.format_quote, scheme),
          ...search.quotes.map((q) => _buildQuoteTile(q, theme, scheme)),
          const SizedBox(height: 16),
        ],

        // ── NOTES ──
        if (search.notes.isNotEmpty) ...[
          _sectionHeader('NOTES (${search.notes.length})', Icons.note, scheme),
          ...search.notes.map((n) => _buildNoteTile(n, theme, scheme)),
          const SizedBox(height: 16),
        ],

        // ── COLLECTIONS ──
        if (search.collections.isNotEmpty) ...[
          _sectionHeader('COLLECTIONS (${search.collections.length})',
              Icons.collections_bookmark, scheme),
          ...search.collections.map((c) => _buildCollectionTile(c, theme, scheme)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              fontSize: 12,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookTile(Book book, ThemeData theme, ColorScheme scheme) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.book_rounded),
        title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRouter.bookDetails,
            arguments: book.id,
          );
        },
      ),
    );
  }

  Widget _buildHighlightTile(
      Highlight h, ThemeData theme, ColorScheme scheme) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 8,
          height: 36,
          decoration: BoxDecoration(
            color: Color(int.parse(h.color.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          '"${h.selectedText}"',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        subtitle: Text('Page ${h.page}'),
        trailing: const Icon(Icons.arrow_forward, size: 16),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRouter.reader,
            arguments: {
              'bookId': h.bookId,
              'page': h.page - 1,
            },
          );
        },
      ),
    );
  }

  Widget _buildQuoteTile(Quote q, ThemeData theme, ColorScheme scheme) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.format_quote_rounded),
        title: Text(
          '"${q.quoteText}"',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        subtitle: Text('${q.bookTitle} · p. ${q.page}'),
        trailing: const Icon(Icons.arrow_forward, size: 16),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRouter.reader,
            arguments: {
              'bookId': q.bookId,
              'page': q.page - 1,
            },
          );
        },
      ),
    );
  }

  Widget _buildNoteTile(Note n, ThemeData theme, ColorScheme scheme) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.note_alt_outlined),
        title: Text(n.noteText, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          'Passage: "${n.selectedText}" · p. ${n.page}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward, size: 16),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRouter.reader,
            arguments: {
              'bookId': n.bookId,
              'page': n.page - 1,
            },
          );
        },
      ),
    );
  }

  Widget _buildCollectionTile(
      Collection c, ThemeData theme, ColorScheme scheme) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.shelves),
        title: Text(c.name),
        subtitle: Text('${c.bookCount} books'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRouter.collectionDetails,
            arguments: c.id,
          );
        },
      ),
    );
  }
}
