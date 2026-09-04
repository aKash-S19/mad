/// Table of Contents slide-in panel for the Libora reader.
///
/// Lists chapters with indentation based on their [Chapter.level]. The
/// current chapter is highlighted. Tapping a chapter navigates to it.
/// Has a close button and a "Contents" header.
library;

import 'package:flutter/material.dart';
import 'package:libora/core/utils/date_formatter.dart';
import 'package:libora/data/models/chapter_model.dart';

class TocPanel extends StatelessWidget {
  /// The table of contents chapters.
  final List<Chapter> chapters;

  /// The index of the current chapter (0-indexed). -1 if none.
  final int currentChapterIndex;

  /// Called when the user taps a chapter to navigate.
  final ValueChanged<Chapter> onChapterSelected;

  /// Called when the close button is tapped.
  final VoidCallback onClose;

  /// Background color for the panel.
  final Color backgroundColor;

  /// Foreground (text) color.
  final Color foregroundColor;

  /// Accent color for the active chapter.
  final Color accentColor;

  const TocPanel({
    super.key,
    required this.chapters,
    this.currentChapterIndex = -1,
    required this.onChapterSelected,
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
                    Text(
                      'Contents',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: foregroundColor,
                      ),
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

              // ── Chapter list ──
              Expanded(
                child: chapters.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No table of contents\navailable for this book.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  foregroundColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = chapters[index];
                          final isCurrent = index == currentChapterIndex;
                          return _ChapterTile(
                            chapter: chapter,
                            isCurrent: isCurrent,
                            foregroundColor: foregroundColor,
                            accentColor: accentColor,
                            onTap: () {
                              onChapterSelected(chapter);
                              onClose();
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
}

class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final bool isCurrent;
  final Color foregroundColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _ChapterTile({
    required this.chapter,
    required this.isCurrent,
    required this.foregroundColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 20.0 + (chapter.level * 20),
          right: 20,
          top: 14,
          bottom: 14,
        ),
        decoration: BoxDecoration(
          color: isCurrent
              ? accentColor.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isCurrent
                  ? accentColor
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                chapter.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrent
                      ? accentColor
                      : foregroundColor.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: accentColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
