/// Highlights Library screen for the Libora reading ecosystem.
///
/// A dedicated knowledge archive allowing users to browse, search, and
/// manage all passages highlighted across their books. Includes filtering
/// by book and color, with direct deep-linking back to the reader page.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:libora/core/router/app_router.dart';
import 'package:libora/core/utils/date_formatter.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/highlight_model.dart';
import 'package:libora/providers/highlights_provider.dart';

class HighlightsScreen extends StatefulWidget {
  const HighlightsScreen({super.key});

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Book> _books = [];
  String? _selectedBookId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final highlightsProvider = context.read<HighlightsProvider>();
    await highlightsProvider.loadHighlights();
    final books = await _db.getAllBooks();
    setState(() {
      _books = books;
    });
  }

  void _shareHighlight(Highlight h, String bookTitle) {
    Share.share('"$h.selectedText"\n\n— $bookTitle (p. ${h.page})\nRead on Libora');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final highlightsProvider = context.watch<HighlightsProvider>();

    var highlights = highlightsProvider.highlights;
    if (_selectedBookId != null) {
      highlights =
          highlights.where((h) => h.bookId == _selectedBookId).toList();
    }
    if (_searchController.text.trim().isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      highlights = highlights
          .where((h) => h.selectedText.toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Highlights Archive'),
      ),
      body: Column(
        children: [
          // ── Search & Filter Row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search within highlighted passages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Book Filter Chips ──
          if (_books.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChip(
                    label: const Text('All Books'),
                    selected: _selectedBookId == null,
                    onSelected: (_) {
                      setState(() => _selectedBookId = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._books.map((b) {
                    final isSelected = b.id == _selectedBookId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(b.title, maxLines: 1),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedBookId = isSelected ? null : b.id;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── Highlights List ──
          Expanded(
            child: highlightsProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : highlights.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.highlight_rounded,
                                  size: 64, color: scheme.outline),
                              const SizedBox(height: 16),
                              Text('No Highlights Saved',
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(
                                'Select text while reading any book to highlight and preserve passages here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: highlights.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final h = highlights[index];
                          final book = _books
                              .where((b) => b.id == h.bookId)
                              .firstOrNull;
                          final bookTitle = book?.title ?? 'Unknown Book';
                          final colorVal = Color(int.parse(
                              h.color.replaceFirst('#', '0xFF')));

                          return Card(
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
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: colorVal,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          bookTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Page ${h.page}',
                                        style: TextStyle(
                                          color: scheme.outline,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '"${h.selectedText}"',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormatter.formatRelativeTime(
                                            h.createdAt),
                                        style: TextStyle(
                                          color: scheme.outline,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.share_outlined,
                                                size: 18),
                                            tooltip: 'Share',
                                            onPressed: () =>
                                                _shareHighlight(h, bookTitle),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18),
                                            tooltip: 'Delete',
                                            onPressed: () {
                                              highlightsProvider
                                                  .deleteHighlight(h.id);
                                            },
                                          ),
                                          FilledButton.tonalIcon(
                                            onPressed: () {
                                              Navigator.of(context).pushNamed(
                                                AppRouter.reader,
                                                arguments: {
                                                  'bookId': h.bookId,
                                                  'page': h.page - 1,
                                                },
                                              );
                                            },
                                            icon: const Icon(
                                                Icons.arrow_forward,
                                                size: 14),
                                            label: const Text('Read'),
                                            style: FilledButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
