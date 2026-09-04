/// Library screen for the Libora app.
///
/// The user's personal book collection. Features:
/// - Search bar to filter books by title/author/description
/// - Filter chips: All / Reading / Want / Completed / Favorites
/// - Sort dropdown: Title / Author / Date / Progress
/// - Grid (2 cols) / List view toggle
/// - Pull-to-refresh
/// - FAB for importing books
///
/// Uses [Consumer] to reactively listen to [LibraryProvider]. Shows
/// an empty state when the library has no books.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../providers/library_provider.dart';
import 'widgets/book_grid_card.dart';
import 'widgets/book_list_tile.dart';
import 'widgets/library_empty_state.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBooks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    if (!mounted) return;
    await context.read<LibraryProvider>().loadBooks();
  }

  /// Opens the file picker to select a book for import.
  Future<void> _importBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.first.path;
      if (filePath == null) return;

      if (!mounted) return;
      final library = context.read<LibraryProvider>();
      final book = await library.importBook(filePath);
      if (book != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${book.title}" added to your library'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                if (mounted) {
                  Navigator.pushNamed(
                    context,
                    AppRouter.bookDetails,
                    arguments: book.id,
                  );
                }
              },
            ),
          ),
        );
      } else if (mounted && library.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(library.error!)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 80,
              automaticallyImplyLeading: false,
              backgroundColor: scheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Library',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                // Sort dropdown
                  Consumer<LibraryProvider>(
                    builder: (context, library, child) {
                      return PopupMenuButton<LibrarySortBy>(
                        icon: const Icon(Icons.sort_rounded),
                        tooltip: 'Sort by',
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          _sortItem(
                            LibrarySortBy.date,
                            'Date Added',
                            Icons.schedule_rounded,
                            library.sortBy,
                          ),
                          _sortItem(
                            LibrarySortBy.title,
                            'Title',
                            Icons.sort_by_alpha_rounded,
                            library.sortBy,
                          ),
                          _sortItem(
                            LibrarySortBy.author,
                            'Author',
                            Icons.person_rounded,
                            library.sortBy,
                          ),
                          _sortItem(
                            LibrarySortBy.progress,
                            'Progress',
                            Icons.trending_up_rounded,
                            library.sortBy,
                          ),
                        ],
                        onSelected: (value) {
                          library.setSortBy(value);
                        },
                      );
                    },
                  ),
                // Grid / List toggle
                  Consumer<LibraryProvider>(
                    builder: (context, library, child) {
                      final isGrid =
                          library.viewMode == LibraryViewMode.grid;
                      return IconButton(
                        icon: Icon(
                          isGrid
                              ? Icons.view_list_rounded
                              : Icons.grid_view_rounded,
                        ),
                        tooltip: isGrid ? 'List view' : 'Grid view',
                        onPressed: () {
                          library.setViewMode(
                            isGrid
                                ? LibraryViewMode.list
                                : LibraryViewMode.grid,
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: _buildSearchBar(context),
              ),
            ),
          ];
        },
        body: Consumer<LibraryProvider>(
          builder: (context, library, child) {
            // ── Loading state ──
            if (library.isLoading && library.books.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // ── Empty state ──
            if (library.books.isEmpty) {
              return LibraryEmptyState(onImport: _importBook);
            }

            final filtered = library.filteredBooks;

            // ── Filtered empty state ──
            if (filtered.isEmpty) {
              return _buildNoResults(context);
            }

            // ── Pull-to-refresh wrapper ──
            return RefreshIndicator(
              onRefresh: _loadBooks,
              child: CustomScrollView(
                slivers: [
                  // Filter chips
                  SliverToBoxAdapter(
                    child: _buildFilterChips(context),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 8),
                  ),
                  // Grid or List
                  if (library.viewMode == LibraryViewMode.grid)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.52,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return BookGridCard(
                                book: filtered[index]);
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return BookListTile(
                                book: filtered[index]);
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importBook,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Import'),
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => library.searchBooks(value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by title or author...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: scheme.onSurfaceVariant,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        library.searchBooks('');
                      },
                    )
                  : null,
              filled: true,
              fillColor:
                  scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: scheme.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isDense: true,
            ),
          ),
        );
      },
    );
  }

  // ── Filter chips ─────────────────────────────────────────────────

  Widget _buildFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Consumer<LibraryProvider>(
      builder: (context, library, child) {
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _filterChip(
                context,
                label: 'All',
                icon: Icons.all_inclusive_rounded,
                status: LibraryFilterStatus.all,
                current: library.filterStatus,
                scheme: scheme,
                library: library,
              ),
              const SizedBox(width: 8),
              _filterChip(
                context,
                label: 'Reading',
                icon: Icons.auto_stories_rounded,
                status: LibraryFilterStatus.currentlyReading,
                current: library.filterStatus,
                scheme: scheme,
                library: library,
              ),
              const SizedBox(width: 8),
              _filterChip(
                context,
                label: 'Want',
                icon: Icons.bookmark_rounded,
                status: LibraryFilterStatus.wantToRead,
                current: library.filterStatus,
                scheme: scheme,
                library: library,
              ),
              const SizedBox(width: 8),
              _filterChip(
                context,
                label: 'Completed',
                icon: Icons.check_circle_rounded,
                status: LibraryFilterStatus.completed,
                current: library.filterStatus,
                scheme: scheme,
                library: library,
              ),
              const SizedBox(width: 8),
              _filterChip(
                context,
                label: 'Favorites',
                icon: Icons.favorite_rounded,
                status: LibraryFilterStatus.favorite,
                current: library.filterStatus,
                scheme: scheme,
                library: library,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required LibraryFilterStatus status,
    required LibraryFilterStatus current,
    required ColorScheme scheme,
    required LibraryProvider library,
  }) {
    final isSelected = status == current;

    return FilterChip(
      label: Text(label),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected
            ? scheme.onSecondaryContainer
            : scheme.onSurfaceVariant,
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) library.setFilterStatus(status);
      },
      selectedColor: scheme.secondaryContainer,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide(
        color: isSelected
            ? Colors.transparent
            : scheme.outlineVariant,
        width: 0.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  // ── Sort menu item ───────────────────────────────────────────────

  PopupMenuEntry<LibrarySortBy> _sortItem(
    LibrarySortBy value,
    String label,
    IconData icon,
    LibrarySortBy current,
  ) {
    final isSelected = value == current;
    return PopupMenuItem<LibrarySortBy>(
      value: value,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        contentPadding: EdgeInsets.zero,
        dense: true,
        trailing: isSelected
            ? Icon(Icons.check_rounded, size: 18)
            : null,
      ),
    );
  }

  // ── No results ───────────────────────────────────────────────────

  Widget _buildNoResults(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No books found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or filters.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
