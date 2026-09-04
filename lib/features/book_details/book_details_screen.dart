/// Book Details screen for the Libora reading ecosystem.
///
/// Displays rich book metadata, reading progress, Letterboxd-style rating
/// and review logging, chapters, highlights, notes, quotes, bookmarks,
/// and collection management. Primary actions include "Continue Reading"
/// and "Start from Beginning".
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:libora/core/router/app_router.dart';
import 'package:libora/core/utils/date_formatter.dart';
import 'package:libora/core/utils/file_utils.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/book_review_model.dart';
import 'package:libora/data/models/bookmark_model.dart';
import 'package:libora/data/models/chapter_model.dart';
import 'package:libora/features/library/widgets/book_cover_widget.dart';
import 'package:libora/providers/collections_provider.dart';
import 'package:libora/providers/library_provider.dart';
import 'package:libora/providers/profile_provider.dart';
import 'package:libora/services/epub_parser_service.dart';

class BookDetailsScreen extends StatefulWidget {
  final String bookId;

  const BookDetailsScreen({super.key, required this.bookId});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  late TabController _tabController;
  Book? _book;
  bool _isLoading = true;

  List<Highlight> _highlights = [];
  List<Note> _notes = [];
  List<Quote> _quotes = [];
  List<Bookmark> _bookmarks = [];
  List<Chapter> _chapters = [];
  List<BookReview> _reviews = [];

  // Rating and review state
  double _userRating = 0.0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadBookDetails() async {
    setState(() => _isLoading = true);

    try {
      final library = context.read<LibraryProvider>();
      Book? book = await library.getBookById(widget.bookId);
      book ??= await _db.getBookById(widget.bookId);

      if (book == null) {
        setState(() => _isLoading = false);
        return;
      }

      _book = book;

      // Load associated entities in parallel
      final results = await Future.wait([
        _db.getHighlightsByBook(book.id),
        _db.getNotesByBook(book.id),
        _db.getQuotesByBook(book.id),
        _db.getBookmarksByBook(book.id),
      ]);

      _highlights = results[0] as List<Highlight>;
      _notes = results[1] as List<Note>;
      _quotes = results[2] as List<Quote>;
      _bookmarks = results[3] as List<Bookmark>;

      // Load reviews
      final profile = context.read<ProfileProvider>();
      _reviews = await profile.getReviewsForBook(book.id);
      if (_reviews.isNotEmpty) {
        _userRating = _reviews.first.rating.toDouble();
        _reviewController.text = _reviews.first.reviewText;
      }

      // Load EPUB chapters if applicable
      if (book.fileType == BookFileType.epub && book.filePath != null) {
        try {
          final epubData = await EpubParserService.parseEpub(book.filePath!);
          _chapters = epubData.chapters;
        } catch (e) {
          debugPrint('BookDetails: EPUB chapter load failed: $e');
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('BookDetails: _loadBookDetails error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _openReader({int? page, int? chapterIndex}) {
    if (_book == null) return;
    Navigator.of(context).pushNamed(
      AppRouter.reader,
      arguments: {
        'bookId': _book!.id,
        if (page != null) 'page': page,
        if (chapterIndex != null) 'chapterIndex': chapterIndex,
      },
    ).then((_) {
      _loadBookDetails();
    });
  }

  Future<void> _updateStatus(ReadingStatus newStatus) async {
    if (_book == null) return;
    final updated = _book!.copyWith(readingStatus: newStatus);
    await context.read<LibraryProvider>().updateBook(updated);
    setState(() => _book = updated);
  }

  Future<void> _saveReview() async {
    if (_book == null) return;
    final text = _reviewController.text.trim();
    if (_userRating == 0 && text.isEmpty) return;

    final review = BookReview(
      id: _reviews.isNotEmpty ? _reviews.first.id : _uuid.v4(),
      bookId: _book!.id,
      bookTitle: _book!.title,
      bookAuthor: _book!.author,
      userId: '',
      rating: _userRating.toInt(),
      reviewText: text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await context.read<ProfileProvider>().addReview(review);
    setState(() {
      _reviews = [review, ..._reviews.where((r) => r.id != review.id)];
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review saved!')),
      );
    }
  }

  void _showAddToCollectionDialog() {
    if (_book == null) return;
    final collectionsProvider = context.read<CollectionsProvider>();
    collectionsProvider.loadCollections();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Consumer<CollectionsProvider>(
        builder: (context, cp, _) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add to Shelf',
                        style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (cp.collections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No custom collections yet. Create one from the Collections tab.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  )
                else
                  ...cp.collections.map((col) {
                    return ListTile(
                      leading:
                          const Icon(Icons.collections_bookmark_outlined),
                      title: Text(col.name),
                      subtitle: Text('${col.bookIds.length} books'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () async {
                          await cp.addBookToCollection(col.id, _book!.id);
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Added to "${col.name}"')),
                            );
                          }
                        },
                      ),
                    );
                  }),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Book not found')),
      );
    }

    final book = _book!;
    final progressPercent = (book.readingProgress * 100).toInt();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  book.readingStatus == ReadingStatus.favorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: book.readingStatus == ReadingStatus.favorite
                      ? Colors.red
                      : null,
                ),
                onPressed: () =>
                    context.read<LibraryProvider>().markAsFavorite(book.id).then((_) {
                  _loadBookDetails();
                }),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined),
                onPressed: _showAddToCollectionDialog,
              ),
              PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Delete Book'),
                        content: Text(
                            'Are you sure you want to remove "${book.title}" from your library?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dCtx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(dCtx).pop(true),
                            style: FilledButton.styleFrom(
                                backgroundColor: scheme.error),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      await context
                          .read<LibraryProvider>()
                          .deleteBook(book.id);
                      if (mounted) Navigator.of(context).pop();
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove Book',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.primary.withValues(alpha: 0.15),
                      scheme.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Cover Card
                        Hero(
                          tag: 'book_cover_${book.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BookCoverWidget(
                              book: book,
                              width: 120,
                              height: 180,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Title, Author, Info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                book.author.isNotEmpty
                                    ? book.author
                                    : 'Unknown Author',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Format and Size Badges
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: scheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      book.fileType.name.toUpperCase(),
                                      style: TextStyle(
                                        color: scheme.onPrimaryContainer,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (book.pageCount != null &&
                                      book.pageCount! > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: scheme.surfaceContainerHighest,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${book.pageCount} pages',
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  if (book.fileSize > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: scheme.surfaceContainerHighest,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        FileUtils.formatFileSize(book.fileSize),
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // ── Primary Action Buttons & Progress ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress ($progressPercent%)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        book.pageCount != null && book.pageCount! > 0
                            ? 'Page ${book.currentPage + 1} of ${book.pageCount}'
                            : 'Page ${book.currentPage + 1}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: book.readingProgress,
                      minHeight: 6,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // CTA Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: FilledButton.icon(
                          onPressed: () => _openReader(page: book.currentPage),
                          icon: const Icon(Icons.auto_stories),
                          label: Text(book.currentPage > 0
                              ? 'Continue Reading'
                              : 'Start Reading'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (book.currentPage > 0) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () => _openReader(page: 0),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('From Start'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Reading Status Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statusChoiceChip('Currently Reading',
                            ReadingStatus.currentlyReading, book),
                        const SizedBox(width: 8),
                        _statusChoiceChip(
                            'Want to Read', ReadingStatus.wantToRead, book),
                        const SizedBox(width: 8),
                        _statusChoiceChip(
                            'Completed', ReadingStatus.completed, book),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Tabs ──
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Chapters (${_chapters.length})'),
                Tab(text: 'Highlights (${_highlights.length})'),
                Tab(text: 'Notes (${_notes.length})'),
                Tab(text: 'Quotes (${_quotes.length})'),
              ],
            ),

            // ── Tab Views ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(book, theme, scheme),
                  _buildChaptersTab(),
                  _buildHighlightsTab(theme, scheme),
                  _buildNotesTab(theme, scheme),
                  _buildQuotesTab(theme, scheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChoiceChip(
      String label, ReadingStatus status, Book currentBook) {
    final isSelected = currentBook.readingStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _updateStatus(status),
    );
  }

  Widget _buildOverviewTab(
      Book book, ThemeData theme, ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text('Description', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            book.description.isNotEmpty
                ? book.description
                : 'No description available for this book.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),

          // Letterboxd-style Review Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Rating & Review',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                    // 5-Star interactive rating
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _userRating = (index + 1).toDouble();
                            });
                          },
                          child: Icon(
                            index < _userRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 26,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Write your personal review (Letterboxd style)...',
                    filled: true,
                    fillColor: scheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: _saveReview,
                    child: const Text('Save Review'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Metadata Table
          Text('Book Details', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _infoRow('Source', book.source.name.toUpperCase()),
          if (book.publisher != null) _infoRow('Publisher', book.publisher!),
          if (book.publishYear != null)
            _infoRow('Published', book.publishYear.toString()),
          if (book.language != null) _infoRow('Language', book.language!),
          if (book.isbn != null) _infoRow('ISBN', book.isbn!),
          _infoRow('Added to Library',
              DateFormatter.formatDate(book.addedAt)),
          if (book.lastOpenedAt != null)
            _infoRow('Last Read',
                DateFormatter.formatRelativeTime(book.lastOpenedAt!)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildChaptersTab() {
    if (_chapters.isEmpty) {
      return const Center(child: Text('No chapters available.'));
    }

    return ListView.builder(
      itemCount: _chapters.length,
      itemBuilder: (context, index) {
        final chapter = _chapters[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 14,
            child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
          ),
          title: Text(chapter.title),
          onTap: () => _openReader(chapterIndex: index),
        );
      },
    );
  }

  Widget _buildHighlightsTab(ThemeData theme, ColorScheme scheme) {
    if (_highlights.isEmpty) {
      return const Center(
          child: Text('No highlights yet. Select text in reader to highlight.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _highlights.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final h = _highlights[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${h.selectedText}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Page ${h.page}',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 12)),
                  TextButton.icon(
                    onPressed: () => _openReader(page: h.page - 1),
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('Jump to Page'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotesTab(ThemeData theme, ColorScheme scheme) {
    if (_notes.isEmpty) {
      return const Center(
          child: Text('No notes yet. Add thoughts to passages while reading.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final n = _notes[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                n.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Passage: "${n.selectedText}"',
                style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openReader(page: n.page - 1),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('Jump to Page'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuotesTab(ThemeData theme, ColorScheme scheme) {
    if (_quotes.isEmpty) {
      return const Center(
          child: Text('No quotes saved yet from this book.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _quotes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final q = _quotes[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${q.quoteText}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('p. ${q.page}',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 12)),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.quoteCard,
                        arguments: q.id,
                      );
                    },
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Quote Card'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
