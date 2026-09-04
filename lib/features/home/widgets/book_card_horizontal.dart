/// Compact horizontal-scrolling book card for the Libora home screen.
///
/// Used in the "Currently Reading" and "Recently Added" horizontal lists.
/// Column layout: cover image on top, then title (2 lines max), author
/// (1 line), and a small progress bar. Width approximately 140px.
/// Tapping the card navigates to the book details screen.
library;

import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/book_model.dart';
import '../../library/widgets/book_cover_widget.dart';

class BookCardHorizontal extends StatelessWidget {
  const BookCardHorizontal({
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
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover image ──
            SizedBox(
              width: 120,
              height: 160,
              child: BookCoverWidget(
                book: book,
                borderRadius: 8,
                showShadow: true,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            // ── Title ──
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
            // ── Author ──
            Text(
              book.author,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // ── Progress bar ──
            if (book.readingProgress > 0)
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
              )
            else
              SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: 0,
                  minHeight: 3,
                  backgroundColor:
                      scheme.primary.withValues(alpha: 0.12),
                ),
              ),
          ],
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
