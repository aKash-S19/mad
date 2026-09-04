/// In-book search bottom sheet for the Libora reader.
///
/// Provides a search field to find text within the current book's chapters.
/// Displays results as a list of matches with surrounding context. Tapping
/// a result navigates to that location.
library;

import 'package:flutter/material.dart';
import 'package:libora/data/models/chapter_model.dart';
import 'package:libora/services/epub_parser_service.dart';

/// A single search match result.
class SearchMatch {
  final int chapterIndex;
  final String chapterTitle;
  final String matchText;
  final String contextBefore;
  final String contextAfter;
  final int offset;

  const SearchMatch({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.matchText,
    required this.contextBefore,
    required this.contextAfter,
    required this.offset,
  });
}

class InBookSearchSheet extends StatefulWidget {
  /// The file path of the book (EPUB file to search).
  final String? filePath;

  /// The chapters to search through.
  final List<Chapter> chapters;

  /// Called when the user taps a search result to navigate to it.
  final ValueChanged<SearchMatch> onMatchSelected;

  const InBookSearchSheet({
    super.key,
    this.filePath,
    required this.chapters,
    required this.onMatchSelected,
  });

  /// Convenience method to show this sheet.
  static Future<void> show(
    BuildContext context, {
    String? filePath,
    required List<Chapter> chapters,
    required ValueChanged<SearchMatch> onMatchSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => InBookSearchSheet(
        filePath: filePath,
        chapters: chapters,
        onMatchSelected: onMatchSelected,
      ),
    );
  }

  @override
  State<InBookSearchSheet> createState() => _InBookSearchSheetState();
}

class _InBookSearchSheetState extends State<InBookSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchMatch> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final matches = <SearchMatch>[];

    for (var i = 0; i < widget.chapters.length; i++) {
      final chapter = widget.chapters[i];
      String? chapterText;

      if (widget.filePath != null) {
        chapterText = await EpubParserService.extractChapterContent(
          widget.filePath!,
          chapter.href,
        );
      }

      if (chapterText == null || chapterText.isEmpty) continue;

      // Strip HTML tags for plain-text search
      final plainText = chapterText
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final lowerText = plainText.toLowerCase();
      final lowerQuery = query.toLowerCase();

      var searchStart = 0;
      while (searchStart < lowerText.length) {
        final matchIndex = lowerText.indexOf(lowerQuery, searchStart);
        if (matchIndex == -1) break;

        // Extract context: 40 chars before and after
        final contextStart = (matchIndex - 40).clamp(0, plainText.length);
        final contextEnd =
            (matchIndex + query.length + 40).clamp(0, plainText.length);

        matches.add(SearchMatch(
          chapterIndex: i,
          chapterTitle: chapter.title,
          matchText: plainText.substring(matchIndex, matchIndex + query.length),
          contextBefore: contextStart < matchIndex
              ? '\u2026${plainText.substring(contextStart, matchIndex)}'
              : plainText.substring(contextStart, matchIndex),
          contextAfter: matchIndex + query.length < contextEnd
              ? '${plainText.substring(matchIndex + query.length, contextEnd)}\u2026'
              : plainText.substring(matchIndex + query.length, contextEnd),
          offset: matchIndex,
        ));

        searchStart = matchIndex + query.length;

        // Limit to 3 matches per chapter
        final countInChapter =
            matches.where((m) => m.chapterIndex == i).length;
        if (countInChapter >= 3) break;
      }

      // Stop after 50 total results
      if (matches.length >= 50) break;
    }

    if (mounted) {
      setState(() {
        _results = matches;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Row(
                  children: [
                    Icon(Icons.search, color: colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    Text('Search in Book', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              // ── Search field ──
              TextField(
                controller: _searchController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search within this book...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _results = []);
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // ── Results count ──
              if (_searchController.text.trim().length >= 2) ...[
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _isSearching
                        ? 'Searching...'
                        : '${_results.length} ${_results.length == 1 ? 'result' : 'results'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],

              // ── Results list ──
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty &&
                            _searchController.text.trim().length >= 2
                        ? _buildNoResults()
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.4),
                            ),
                            itemBuilder: (context, index) {
                              final match = _results[index];
                              return _SearchResultTile(
                                match: match,
                                onTap: () {
                                  widget.onMatchSelected(match);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No matches found.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchMatch match;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter title
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  size: 14,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    match.chapterTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Context with highlighted match
            RichText(
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                children: [
                  TextSpan(text: match.contextBefore),
                  TextSpan(
                    text: match.matchText,
                    style: TextStyle(
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.2),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(text: match.contextAfter),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
