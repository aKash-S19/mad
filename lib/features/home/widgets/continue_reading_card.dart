/// Continue Reading card for the Libora home screen.
///
/// Large, attractive card showing the book the user was last reading.
/// Row layout: cover image on the left, book info and progress on the
/// right, with a "Continue Reading" call-to-action button.
library;

import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/book_model.dart';
import '../../library/widgets/book_cover_widget.dart';

class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.book,
  });

  final Book book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progressPercent = (book.readingProgress * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Card(
        elevation: 4,
        shadowColor: scheme.shadow.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openReader(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover image ──
                SizedBox(
                  height: 160,
                  width: 110,
                  child: BookCoverWidget(
                    book: book,
                    borderRadius: 8,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                // ── Info column ──
                Expanded(
                  child: SizedBox(
                    height: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          book.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Author
                        Text(
                          book.author,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        // Progress percentage
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$progressPercent% complete',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (book.pageCount != null)
                              Text(
                                '${book.currentPage}/${book.pageCount} pages',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: book.readingProgress.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor:
                                scheme.primary.withValues(alpha: 0.12),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    scheme.primary),
                          ),
                        ),
                        const Spacer(),
                        // Continue Reading button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _openReader(context),
                            icon: const Icon(
                                Icons.auto_stories_rounded, size: 18),
                            label: const Text('Continue Reading'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the reader for this book.
  void _openReader(BuildContext context) {
    Navigator.pushNamed(context, AppRouter.reader, arguments: book.id);
  }
}
