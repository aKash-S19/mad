/// List tile for the Libora library screen (list view mode).
///
/// Compact horizontal row: thumbnail (50x65) on the left, then title,
/// author, status icon, and a thin progress bar. A "more" menu on the
/// right provides quick actions. Tapping the tile navigates to the
/// book details screen.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/book_model.dart';
import '../../../providers/library_provider.dart';
import 'book_cover_widget.dart';

class BookListTile extends StatelessWidget {
  const BookListTile({
    super.key,
    required this.book,
  });

  final Book book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openBookDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // ── Thumbnail ──
              SizedBox(
                width: 50,
                height: 65,
                child: BookCoverWidget(
                  book: book,
                  borderRadius: 6,
                  showShadow: false,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              // ── Title + author + progress ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Status icon
                        _StatusIcon(status: book.readingStatus),
                        const SizedBox(width: 6),
                        // Progress bar
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child:
                                LinearProgressIndicator(
                              value: book.readingProgress
                                  .clamp(0.0, 1.0),
                              minHeight: 3,
                              backgroundColor: scheme.primary
                                  .withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                scheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Progress percentage
                        Text(
                          '${(book.readingProgress * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── More menu ──
              const SizedBox(width: 4),
              _MoreMenu(book: book),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigates to the book details screen.
  void _openBookDetails(BuildContext context) {
    Navigator.pushNamed(context, AppRouter.bookDetails,
        arguments: book.id);
  }
}

// ── Status icon ───────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final ReadingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, colour) = _iconData(scheme);

    return Icon(icon, size: 14, color: colour);
  }

  (IconData, Color) _iconData(ColorScheme scheme) {
    switch (status) {
      case ReadingStatus.currentlyReading:
        return (Icons.auto_stories_rounded, scheme.primary);
      case ReadingStatus.completed:
        return (Icons.check_circle_rounded, Colors.green);
      case ReadingStatus.favorite:
        return (Icons.favorite_rounded, Colors.red.shade400);
      case ReadingStatus.wantToRead:
        return (Icons.bookmark_outline_rounded, scheme.onSurfaceVariant);
    }
  }
}

// ── More menu (popup) ──────────────────────────────────────────────

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryProvider>();

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'details',
          child: ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Book Details'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (book.readingStatus != ReadingStatus.currentlyReading)
          const PopupMenuItem(
            value: 'reading',
            child: ListTile(
              leading: Icon(Icons.auto_stories_rounded),
              title: Text('Mark as Reading'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        if (book.readingStatus != ReadingStatus.completed)
          const PopupMenuItem(
            value: 'completed',
            child: ListTile(
              leading: Icon(Icons.check_circle_rounded),
              title: Text('Mark as Completed'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        const PopupMenuItem(
          value: 'favorite',
          child: ListTile(
            leading: Icon(Icons.favorite_outline_rounded),
            title: Text('Toggle Favorite'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline_rounded),
            title: Text('Remove from Library'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'details':
            if (context.mounted) {
              Navigator.pushNamed(
                context,
                AppRouter.bookDetails,
                arguments: book.id,
              );
            }
            break;
          case 'reading':
            await library.markAsReading(book.id);
            break;
          case 'completed':
            await library.markAsCompleted(book.id);
            break;
          case 'favorite':
            await library.markAsFavorite(book.id);
            break;
          case 'delete':
            await library.deleteBook(book.id);
            break;
        }
      },
    );
  }
}
