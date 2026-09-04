/// Grid card for the Libora library screen.
///
/// Displays a book in a grid layout: cover image with 3:4 aspect ratio
/// and rounded corners, a status badge in the top-right corner, the
/// book title (2 lines max), author (1 line), and a progress bar.
/// Tapping the card navigates to the book details screen.
library;

import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/book_model.dart';
import 'book_cover_widget.dart';

class BookGridCard extends StatelessWidget {
  const BookGridCard({
    super.key,
    required this.book,
  });

  final Book book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _openBookDetails(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Cover with status badge ──
            Stack(
              children: [
                BookCoverWidget(
                  book: book,
                  borderRadius: 8,
                  showShadow: false,
                  fit: BoxFit.cover,
                ),
                // Status badge
                if (_statusBadge() != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _StatusBadge(
                      status: book.readingStatus,
                      scheme: scheme,
                    ),
                  ),
              ],
            ),
            // ── Text section ──
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    book.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: scheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Author
                  Text(
                    book.author,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: book.readingProgress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor:
                          scheme.primary.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a non-null value if the status warrants a badge.
  /// (Helper for conditional rendering.)
  bool? _statusBadge() {
    switch (book.readingStatus) {
      case ReadingStatus.currentlyReading:
        return true;
      case ReadingStatus.completed:
        return true;
      case ReadingStatus.favorite:
        return true;
      case ReadingStatus.wantToRead:
        return null;
    }
  }

  /// Navigates to the book details screen.
  void _openBookDetails(BuildContext context) {
    Navigator.pushNamed(context, AppRouter.bookDetails,
        arguments: book.id);
  }
}

// ── Status badge ──────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.scheme,
  });

  final ReadingStatus status;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final (icon, colour) = _badgeData();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 12,
        color: _isLight(colour) ? Colors.black87 : Colors.white,
      ),
    );
  }

  (IconData, Color) _badgeData() {
    switch (status) {
      case ReadingStatus.currentlyReading:
        return (Icons.auto_stories_rounded, scheme.primary);
      case ReadingStatus.completed:
        return (Icons.check_circle_rounded, Colors.green);
      case ReadingStatus.favorite:
        return (Icons.favorite_rounded, Colors.red.shade400);
      case ReadingStatus.wantToRead:
        return (Icons.bookmark_rounded, scheme.secondary);
    }
  }

  bool _isLight(Color colour) {
    return colour.computeLuminance() > 0.5;
  }
}
