/// Home screen for the Libora reading ecosystem.
///
/// A premium, calm, reading-focused landing page that greets the user and
/// surfaces the most relevant content:
///
/// - Greeting header ("Good morning / afternoon / evening") with user name
/// - Continue Reading: large card for the most recently opened book
/// - Currently Reading: horizontal list of books being read
/// - Recently Added: horizontal list of recently imported/downloaded books
/// - Recent Highlights: vertical list of the latest highlights
///
/// Uses [CustomScrollView] with slivers for smooth scrolling. Shimmer
/// loading effects are shown while data loads. Empty states are
/// encouraging and unobtrusive.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:libora/core/router/app_router.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/providers/auth_provider.dart';
import 'package:libora/providers/highlights_provider.dart';
import 'package:libora/providers/library_provider.dart';
import 'package:libora/features/home/widgets/continue_reading_card.dart';
import 'package:libora/features/home/widgets/book_card_horizontal.dart';
import 'package:libora/features/home/widgets/recent_highlight_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Defer provider calls until after the first frame so that
    // the widgets are mounted and inherited lookups are safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final library = context.read<LibraryProvider>();
    final highlights = context.read<HighlightsProvider>();
    await Future.wait([
      library.loadBooks(),
      highlights.loadHighlights(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Consumer2<LibraryProvider, HighlightsProvider>(
      builder: (context, library, highlights, _) {
        final isLoading = library.isLoading || highlights.isLoading;
        final lastOpenedBook = library.getLastOpenedBook();
        final currentlyReading = library.getCurrentlyReading();
        final recentlyAdded = library.getRecentlyAdded(limit: 10);
        final recentHighlights = highlights.highlights.take(5).toList();

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _loadData,
            color: scheme.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ── Greeting header ──
                SliverToBoxAdapter(
                  child: _GreetingHeader(),
                ),
                // ── Body ──
                if (isLoading)
                  SliverToBoxAdapter(child: _buildShimmerBody())
                else ...[
                  // Continue Reading
                  if (lastOpenedBook != null) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Continue Reading',
                        icon: Icons.auto_stories_rounded,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ContinueReadingCard(
                          book: lastOpenedBook,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                  // Currently Reading
                  if (currentlyReading.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Currently Reading',
                        icon: Icons.menu_book_rounded,
                        count: currentlyReading.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _HorizontalBookList(
                        books: currentlyReading,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                  // Recently Added
                  if (recentlyAdded.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Recently Added',
                        icon: Icons.new_releases_rounded,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _HorizontalBookList(
                        books: recentlyAdded
                            .where((b) =>
                                b.readingStatus !=
                                ReadingStatus.currentlyReading)
                            .take(10)
                            .toList(),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                  // Recent Highlights
                  if (recentHighlights.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Recent Highlights',
                        icon: Icons.highlight_rounded,
                        onSeeAll: () => Navigator.of(context)
                            .pushNamed(AppRouter.highlights),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final highlight = recentHighlights[index];
                          final book = library.books
                              .where((b) => b.id == highlight.bookId)
                              .firstOrNull;
                          if (book == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: RecentHighlightTile(
                              highlight: highlight,
                            ),
                          );
                        },
                        childCount: recentHighlights.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 32),
                    ),
                  ],
                  // Empty state
                  if (lastOpenedBook == null &&
                      currentlyReading.isEmpty &&
                      recentlyAdded.isEmpty &&
                      recentHighlights.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerBody() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _ShimmerBox(height: 24, width: 180),
            const SizedBox(height: 16),
            _ShimmerBox(height: 160, width: double.infinity),
            const SizedBox(height: 24),
            _ShimmerBox(height: 24, width: 140),
            const SizedBox(height: 16),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 14),
                itemBuilder: (_, __) => _ShimmerBox(
                  height: 210,
                  width: 140,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_library_rounded,
                size: 56,
                color: scheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Libora',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your reading journey begins here. Import a book or '
              'browse the catalog to discover your next great read.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRouter.library),
                  icon: const Icon(Icons.library_books_rounded, size: 20),
                  label: const Text('Go to Library'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 48),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppRouter.browse),
                  icon: const Icon(Icons.explore_rounded, size: 20),
                  label: const Text('Browse'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 48),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Greeting header ──────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final userName = auth.currentUser?.displayName.isNotEmpty == true
        ? auth.currentUser!.displayName.split(' ').first
        : 'Reader';

    final hour = DateTime.now().hour;
    final (greeting, emoji) = _greetingForHour(hour);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$userName $emoji',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            // Avatar / profile button
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(AppRouter.profile),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
                child: auth.currentUser?.photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          auth.currentUser!.photoUrl!,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: scheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: scheme.primary,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String) _greetingForHour(int hour) {
    if (hour < 12) return ('Good morning', '\u{1F304}');
    if (hour < 17) return ('Good afternoon', '\u{2600}\u{FE0F}');
    return ('Good evening', '\u{1F319}');
  }
}

// ── Section header ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.count,
    this.onSeeAll,
  });

  final String title;
  final IconData icon;
  final int? count;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                'See all',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Horizontal book list ─────────────────────────────────────────────

class _HorizontalBookList extends StatelessWidget {
  const _HorizontalBookList({required this.books});

  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 215,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) => BookCardHorizontal(
          book: books[index],
        ),
      ),
    );
  }
}

// ── Shimmer helpers ───────────────────────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.height, required this.width});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
