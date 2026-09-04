/// Bottom control bar for the Libora reader.
///
/// Shows a page indicator, slider for page navigation, prev/next buttons,
/// and a settings gear button. Animates up/down when controls toggle.
library;

import 'package:flutter/material.dart';

class ReaderControlsBar extends StatelessWidget {
  /// Current page number (0-indexed internally, displayed 1-indexed).
  final int currentPage;

  /// Total number of pages.
  final int totalPages;

  /// Whether the controls are visible (controls slide animation).
  final bool isVisible;

  /// Called when the user drags the slider to a new page.
  final ValueChanged<int> onPageChanged;

  /// Called when the user taps the previous page button.
  final VoidCallback onPreviousPage;

  /// Called when the user taps the next page button.
  final VoidCallback onNextPage;

  /// Called when the user taps the settings button.
  final VoidCallback onSettings;

  /// The color scheme to use for the bar background and icons.
  final Color backgroundColor;
  final Color foregroundColor;
  final Color accentColor;

  const ReaderControlsBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isVisible,
    required this.onPageChanged,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onSettings,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final displayPage = currentPage + 1;
    final displayTotal = totalPages > 0 ? totalPages : 1;
    final sliderValue = totalPages > 0
        ? (currentPage + 1).toDouble().clamp(1, totalPages.toDouble())
        : 1.0;

    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: BorderSide(
                color: foregroundColor.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Slider row ──
                  Row(
                    children: [
                      // Previous button
                      IconButton(
                        onPressed: currentPage > 0 ? onPreviousPage : null,
                        icon: const Icon(Icons.chevron_left),
                        color: foregroundColor,
                        disabledColor:
                            foregroundColor.withValues(alpha: 0.3),
                        iconSize: 28,
                        tooltip: 'Previous page',
                      ),

                      // Slider
                      Expanded(
                        child: Slider(
                          value: sliderValue,
                          min: 1,
                          max: displayTotal.toDouble(),
                          divisions: displayTotal > 1 ? displayTotal - 1 : 1,
                          activeColor: accentColor,
                          inactiveColor:
                              accentColor.withValues(alpha: 0.2),
                          onChanged: totalPages > 0
                              ? (value) =>
                                  onPageChanged(value.round() - 1)
                              : null,
                          onChangeEnd: totalPages > 0
                              ? (value) =>
                                  onPageChanged(value.round() - 1)
                              : null,
                        ),
                      ),

                      // Next button
                      IconButton(
                        onPressed: currentPage < totalPages - 1
                            ? onNextPage
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        color: foregroundColor,
                        disabledColor:
                            foregroundColor.withValues(alpha: 0.3),
                        iconSize: 28,
                        tooltip: 'Next page',
                      ),
                    ],
                  ),

                  // ── Bottom row: page indicator + settings ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page indicator
                        Text(
                          '$displayPage / $displayTotal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: foregroundColor.withValues(alpha: 0.7),
                            letterSpacing: 0.3,
                          ),
                        ),

                        // Settings button
                        IconButton(
                          onPressed: onSettings,
                          icon: const Icon(Icons.tune),
                          color: foregroundColor,
                          iconSize: 22,
                          tooltip: 'Reader settings',
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
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
    );
  }
}
