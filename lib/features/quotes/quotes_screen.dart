/// Quotes Library screen for the Libora reading ecosystem.
///
/// Browse and manage all saved quotes. Features search, author/book filters,
/// favorite quotes toggle, deep-linking into reader, and Quote Card creation.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:libora/core/router/app_router.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/providers/quotes_provider.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Book> _books = [];
  String? _selectedBookId;
  bool _onlyFavorites = false;

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
    await context.read<QuotesProvider>().loadQuotes();
    final books = await _db.getAllBooks();
    setState(() => _books = books);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final quotesProvider = context.watch<QuotesProvider>();

    var quotes = quotesProvider.quotes;
    if (_selectedBookId != null) {
      quotes = quotes.where((q) => q.bookId == _selectedBookId).toList();
    }
    if (_onlyFavorites) {
      quotes = quotes.where((q) => q.isFavorite).toList();
    }
    if (_searchController.text.trim().isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      quotes = quotes
          .where((item) =>
              item.quoteText.toLowerCase().contains(q) ||
              item.author.toLowerCase().contains(q) ||
              item.bookTitle.toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Collection'),
        actions: [
          IconButton(
            icon: Icon(
              _onlyFavorites ? Icons.favorite : Icons.favorite_border,
              color: _onlyFavorites ? Colors.red : null,
            ),
            tooltip: 'Show Favorites',
            onPressed: () {
              setState(() => _onlyFavorites = !_onlyFavorites);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search quotes, authors, or books...',
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
                    onSelected: (_) => setState(() => _selectedBookId = null),
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

          // ── Quotes List ──
          Expanded(
            child: quotesProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : quotes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.format_quote_rounded,
                                  size: 64, color: scheme.outline),
                              const SizedBox(height: 16),
                              Text('No Quotes Found',
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(
                                'Select meaningful passages while reading and tap "Quote" to collect them here.',
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
                        itemCount: quotes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final q = quotes[index];

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
                                  // Opening quote mark
                                  Icon(Icons.format_quote_rounded,
                                      color: scheme.primary, size: 28),
                                  const SizedBox(height: 6),

                                  // Quote text
                                  Text(
                                    '"${q.quoteText}"',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Author & Book
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '— ${q.author.isNotEmpty ? q.author : "Unknown"}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: scheme.primary,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${q.bookTitle}${q.page > 0 ? " · p. ${q.page}" : ""}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          q.isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: q.isFavorite
                                              ? Colors.red
                                              : null,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          quotesProvider.toggleFavorite(q.id);
                                        },
                                      ),
                                    ],
                                  ),

                                  const Divider(height: 20),

                                  // Actions: Card Generator & Read
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      FilledButton.tonalIcon(
                                        onPressed: () {
                                          Navigator.of(context).pushNamed(
                                            AppRouter.quoteCard,
                                            arguments: q.id,
                                          );
                                        },
                                        icon: const Icon(Icons.palette_outlined,
                                            size: 16),
                                        label: const Text('Share Card'),
                                        style: FilledButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18),
                                            tooltip: 'Delete',
                                            onPressed: () {
                                              quotesProvider.deleteQuote(q.id);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.arrow_forward,
                                                size: 18),
                                            tooltip: 'Jump to Page',
                                            onPressed: () {
                                              Navigator.of(context).pushNamed(
                                                AppRouter.reader,
                                                arguments: {
                                                  'bookId': q.bookId,
                                                  'page': q.page - 1,
                                                },
                                              );
                                            },
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
