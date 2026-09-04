/// Browse and Discover screen for the Libora reading ecosystem.
///
/// Enables book discovery across public-domain and open-access sources
/// including Project Gutenberg (Gutendex API) and Open Library.
/// Features search by title/author, category browsing, trending titles,
/// and integrated downloading directly into the user's personal library.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:libora/core/router/app_router.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/remote_book_model.dart';
import 'package:libora/providers/browse_provider.dart';
import 'package:libora/providers/download_provider.dart';
import 'package:libora/providers/library_provider.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Philosophy';

  final List<String> _categories = [
    'Philosophy',
    'Classic Literature',
    'Science Fiction',
    'History',
    'Psychology',
    'Poetry',
    'Adventure',
    'Politics',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final browse = context.read<BrowseProvider>();
    await browse.getTrending();
    if (browse.trendingBooks.isEmpty) {
      await browse.searchBooks(_selectedCategory);
    }
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) return;
    context.read<BrowseProvider>().searchBooks(query.trim());
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    _searchController.text = category;
    context.read<BrowseProvider>().searchBooks(category);
  }

  Future<void> _downloadAndAddToLibrary(RemoteBook remoteBook) async {
    final downloadProvider = context.read<DownloadProvider>();
    final libraryProvider = context.read<LibraryProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading "${remoteBook.title}"...')),
    );

    final filePath = await downloadProvider.downloadBook(remoteBook);

    if (filePath != null && mounted) {
      final book = await libraryProvider.importBook(filePath);
      if (book != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${book.title}" added to your library!'),
            action: SnackBarAction(
              label: 'Read Now',
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRouter.reader,
                  arguments: book.id,
                );
              },
            ),
          ),
        );
      }
    } else if (downloadProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(downloadProvider.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final browse = context.watch<BrowseProvider>();
    final downloadProvider = context.watch<DownloadProvider>();
    final library = context.watch<LibraryProvider>();

    final isSearching = browse.searchQuery.isNotEmpty;
    final displayBooks = isSearching ? browse.searchResults : browse.trendingBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Active Downloads',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.downloadManager),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (isSearching) {
            await browse.searchBooks(browse.searchQuery);
          } else {
            await browse.getTrending();
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── Search Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search free books, authors, topics...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              browse.searchBooks('');
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
            ),

            // ── Category Pills ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => _onCategorySelected(cat),
                    );
                  },
                ),
              ),
            ),

            // ── Section Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSearching
                          ? 'Results for "${browse.searchQuery}"'
                          : 'Popular & Public Domain Discoveries',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isSearching)
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          browse.searchBooks('');
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ),
            ),

            // ── Book List or Shimmer ──
            if (browse.isLoading)
              SliverToBoxAdapter(child: _buildShimmerLoading())
            else if (displayBooks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 64, color: scheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          isSearching
                              ? 'No books found matching "${browse.searchQuery}".'
                              : 'No books available right now.',
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Try searching for classics like "Pride and Prejudice", "Frankenstein", or "The Republic".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = displayBooks[index];
                      final isDownloading = downloadProvider.activeDownloads
                          .containsKey(book.id);
                      final progress =
                          downloadProvider.activeDownloads[book.id] ?? 0.0;
                      final alreadyInLibrary = library.books.any((b) =>
                          b.title.toLowerCase() == book.title.toLowerCase());

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: scheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Book Cover
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: book.coverUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: book.coverUrl!,
                                        width: 70,
                                        height: 105,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          width: 70,
                                          height: 105,
                                          color: scheme.surfaceContainerHighest,
                                          child: const Icon(Icons.book, size: 28),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          width: 70,
                                          height: 105,
                                          color: scheme.surfaceContainerHighest,
                                          child: const Icon(Icons.book, size: 28),
                                        ),
                                      )
                                    : Container(
                                        width: 70,
                                        height: 105,
                                        color: scheme.primaryContainer,
                                        child: Center(
                                          child: Icon(Icons.auto_stories,
                                              color: scheme.primary),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),

                              // Book Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      book.author.isNotEmpty
                                          ? book.author
                                          : 'Unknown Author',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Format Tag & Source
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: scheme.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            book.fileType.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: scheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          book.source == RemoteBookSource.gutenberg
                                              ? 'Project Gutenberg'
                                              : 'Open Library',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: scheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Action / Progress Button
                                    if (isDownloading)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          LinearProgressIndicator(
                                              value: progress),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Downloading ${(progress * 100).toInt()}%',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      )
                                    else if (alreadyInLibrary)
                                      FilledButton.tonalIcon(
                                        onPressed: () {
                                          final libBook = library.books.firstWhere(
                                              (b) =>
                                                  b.title.toLowerCase() ==
                                                  book.title.toLowerCase());
                                          Navigator.of(context).pushNamed(
                                            AppRouter.bookDetails,
                                            arguments: libBook.id,
                                          );
                                        },
                                        icon: const Icon(Icons.check, size: 16),
                                        label: const Text('In Library'),
                                      )
                                    else
                                      FilledButton.icon(
                                        onPressed: book.downloadUrl != null
                                            ? () => _downloadAndAddToLibrary(book)
                                            : null,
                                        icon: const Icon(Icons.download, size: 16),
                                        label: const Text('Download Free'),
                                        style: FilledButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: displayBooks.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(
            5,
            (_) => Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
