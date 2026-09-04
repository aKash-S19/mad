/// Bookmarks slide-in panel for the Libora reader.
///
/// Shows all bookmarks for the current book. Each bookmark displays its
/// title (or "Page X"), page number, chapter, and timestamp. Includes an
/// "add bookmark" button. Long-press to delete. Tap to navigate.
library;

import 'package:flutter/material.dart';
import 'package:libora/core/utils/date_formatter.dart';
import 'package:libora/data/models/bookmark_model.dart';

class BookmarksPanel extends StatelessWidget {
  /// The bookmarks to display.
  final List<Bookmark> bookmarks;

  /// The current page (0-indexed) — used to highlight nearby bookmarks.
  final int currentPage;

  /// Called when the user taps a bookmark to navigate to it.
  final ValueChanged<Bookmark> onBookmarkSelected;

  /// Called when the user taps the "add bookmark" button.
  final VoidCallback onAddBookmark;

  /// Called when the user long-presses a bookmark to delete it.
  final ValueChanged<Bookmark> onDeleteBookmark;

  /// Called when the close button is tapped.
  final VoidCallback onClose;

  /// Colors.
  final Color backgroundColor;
  final Color foregroundColor;
  final Color accentColor;

  const BookmarksPanel({
    super.key,
    required this.bookmarks,
    this.currentPage = 0,
    required this.onBookmarkSelected,
    required this.onAddBookmark,
    required this.onDeleteBookmark,
    required this.onClose,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.82,
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 12, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bookmark,
                            color: accentColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Bookmarks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: foregroundColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                      color: foregroundColor,
                      iconSize: 24,
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: foregroundColor.withValues(alpha: 0.1),
              ),

              // ── Bookmark list ──
              Expanded(
                child: bookmarks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: bookmarks.length,
                        itemBuilder: (context, index) {
                          final bookmark = bookmarks[index];
                          final isCurrent = bookmark.page == currentPage;
                          return _BookmarkTile(
                            bookmark: bookmark,
                            isCurrent: isCurrent,
                            foregroundColor: foregroundColor,
                            accentColor: accentColor,
                            onTap: () {
                              onBookmarkSelected(bookmark);
                              onClose();
                            },
                            onLongPress: () =>
                                _confirmDelete(context, bookmark),
                          );
                        },
                      ),
              ),

              // ── Add bookmark button ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: onAddBookmark,
                  icon: const Icon(Icons.bookmark_add, size: 20),
                  label: const Text('Add Bookmark'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 48,
              color: foregroundColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No bookmarks yet.\nBookmark a page to return to it later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: foregroundColor.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Bookmark?'),
        content: Text(
          bookmark.title != null
              ? '"${bookmark.title}" on page ${bookmark.page + 1}'
              : 'Bookmark on page ${bookmark.page + 1}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onDeleteBookmark(bookmark);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final Bookmark bookmark;
  final bool isCurrent;
  final Color foregroundColor;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BookmarkTile({
    required this.bookmark,
    required this.isCurrent,
    required this.foregroundColor,
    required this.accentColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = bookmark.title ??
        'Page ${bookmark.page + 1}';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isCurrent
              ? accentColor.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isCurrent ? accentColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bookmark icon
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isCurrent ? Icons.bookmark : Icons.bookmark_border,
                size: 18,
                color: isCurrent
                    ? accentColor
                    : foregroundColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCurrent
                          ? accentColor
                          : foregroundColor.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (bookmark.chapter != null) ...[
                        Flexible(
                          child: Text(
                            bookmark.chapter!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: foregroundColor
                                  .withValues(alpha: 0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '\u00B7',
                          style: TextStyle(
                            fontSize: 12,
                            color: foregroundColor
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        'Page ${bookmark.page + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: foregroundColor
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '\u00B7',
                        style: TextStyle(
                          fontSize: 12,
                          color: foregroundColor
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          DateFormatter.formatRelativeTime(
                              bookmark.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: foregroundColor
                                .withValues(alpha: 0.5),
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
    );
  }
}
