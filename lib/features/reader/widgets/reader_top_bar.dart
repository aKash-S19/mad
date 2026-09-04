/// Top app bar for the Libora reader.
///
/// Shows a back button, centered book title (with ellipsis), and action
/// buttons: TOC, bookmarks, search-in-book, and reader settings. Animates
/// up/down when controls toggle.
library;

import 'package:flutter/material.dart';

class ReaderTopBar extends StatelessWidget {
  /// The book title to display (centered, truncated with ellipsis).
  final String bookTitle;

  /// Whether the controls are visible.
  final bool isVisible;

  /// Called when the back button is tapped.
  final VoidCallback onBack;

  /// Called when the TOC button is tapped.
  final VoidCallback onTOC;

  /// Called when the bookmarks button is tapped.
  final VoidCallback onBookmarks;

  /// Called when the search button is tapped.
  final VoidCallback onSearch;

  /// Called when the settings button is tapped.
  final VoidCallback onSettings;

  /// Colors for the bar.
  final Color backgroundColor;
  final Color foregroundColor;

  const ReaderTopBar({
    super.key,
    required this.bookTitle,
    required this.isVisible,
    required this.onBack,
    required this.onTOC,
    required this.onBookmarks,
    required this.onSearch,
    required this.onSettings,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              bottom: BorderSide(
                color: foregroundColor.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: NavigationToolbar(
                leading: IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  color: foregroundColor,
                  tooltip: 'Back',
                ),
                middle: Text(
                  bookTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: foregroundColor,
                    letterSpacing: 0.2,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onTOC,
                      icon: const Icon(Icons.list),
                      color: foregroundColor,
                      tooltip: 'Contents',
                      iconSize: 22,
                    ),
                    IconButton(
                      onPressed: onBookmarks,
                      icon: const Icon(Icons.bookmark_border),
                      color: foregroundColor,
                      tooltip: 'Bookmarks',
                      iconSize: 22,
                    ),
                    IconButton(
                      onPressed: onSearch,
                      icon: const Icon(Icons.search),
                      color: foregroundColor,
                      tooltip: 'Search in book',
                      iconSize: 22,
                    ),
                    IconButton(
                      onPressed: onSettings,
                      icon: const Icon(Icons.text_fields),
                      color: foregroundColor,
                      tooltip: 'Reader settings',
                      iconSize: 22,
                    ),
                  ],
                ),
                centerMiddle: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
