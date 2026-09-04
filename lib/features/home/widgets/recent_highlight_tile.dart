/// Recent highlight tile for the Libora home screen.
///
/// Displays a highlighted text passage with a coloured left border
/// (derived from the highlight's colour field), the book title, page
/// or chapter location, and a relative timestamp. Tapping the tile
/// opens the book in the reader at the highlight's location.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/highlight_model.dart';
import '../../../providers/library_provider.dart';

class RecentHighlightTile extends StatelessWidget {
  const RecentHighlightTile({
    super.key,
    required this.highlight,
  });

  final Highlight highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Resolve the highlight colour from hex string to a Color.
    final borderColor = _resolveColour(highlight.color);
    final bookTitle = _lookupBookTitle(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openReader(context),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest
                  .withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: BorderDirectional(
                start: BorderSide(
                  color: borderColor,
                  width: 4,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Highlighted text ──
                Text(
                  '"${highlight.selectedText}"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    color: scheme.onSurface,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // ── Book title ──
                Row(
                  children: [
                    Icon(
                      Icons.book_rounded,
                      size: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        bookTitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // ── Page/chapter + timestamp ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _locationLabel(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormatter.formatRelativeTime(
                        highlight.createdAt,
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Resolves a hex colour string like "#FFEB3B" or "FFEB3B" to a [Color].
  Color _resolveColour(String hex) {
    try {
      return Color(AppConstants.hexToInt(hex));
    } catch (_) {
      return const Color(0xFFFFEB3B); // default yellow
    }
  }

  /// Looks up the book title from LibraryProvider.
  /// Falls back to "Unknown book" if not found.
  String _lookupBookTitle(BuildContext context) {
    try {
      final library = context.read<LibraryProvider>();
      for (final book in library.books) {
        if (book.id == highlight.bookId) return book.title;
      }
    } catch (_) {
      // Provider might not be available — safe fallback.
    }
    return 'Unknown book';
  }

  /// Builds a human-readable location label from chapter/page info.
  String _locationLabel() {
    final parts = <String>[];
    if (highlight.chapter != null && highlight.chapter!.isNotEmpty) {
      parts.add(highlight.chapter!);
    } else if (highlight.page > 0) {
      parts.add('Page ${highlight.page}');
    }
    if (parts.isEmpty) return 'Unknown location';
    return parts.join(' · ');
  }

  /// Opens the reader for this highlight's book.
  void _openReader(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRouter.reader,
      arguments: {
        'bookId': highlight.bookId,
        if (highlight.page > 0) 'page': highlight.page,
        if (highlight.location.isNotEmpty) 'location': highlight.location,
      },
    );
  }
}
