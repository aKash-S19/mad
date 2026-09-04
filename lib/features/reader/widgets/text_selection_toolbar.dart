/// Text selection toolbar for the Libora reader.
///
/// A floating, rounded toolbar that appears above the selected text in the
/// reader. Shows five actions: Highlight (expands to color picker), Note,
/// Quote, Copy, and Share. Modern design with shadow and rounded corners.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libora/features/reader/widgets/highlight_color_picker.dart';

/// A single action in the selection toolbar.
class _ToolbarAction {
  final IconData icon;
  final String label;
  const _ToolbarAction(this.icon, this.label);
}

class TextSelectionToolbar extends StatefulWidget {
  /// The selected text to operate on.
  final String selectedText;

  /// Called when the user picks a highlight color.
  final ValueChanged<String> onHighlight;

  /// Called when the user taps Note.
  final VoidCallback onNote;

  /// Called when the user taps Quote.
  final VoidCallback onQuote;

  /// Called when the user taps Copy. If not provided, the toolbar handles
  /// the clipboard copy internally.
  final VoidCallback? onCopy;

  /// Called when the user taps Share.
  final VoidCallback onShare;

  /// Called when the toolbar is dismissed (e.g. user taps outside or
  /// selects an action that closes it).
  final VoidCallback onDismiss;

  const TextSelectionToolbar({
    super.key,
    required this.selectedText,
    required this.onHighlight,
    required this.onNote,
    required this.onQuote,
    this.onCopy,
    required this.onShare,
    required this.onDismiss,
  });

  @override
  State<TextSelectionToolbar> createState() => _TextSelectionToolbarState();
}

class _TextSelectionToolbarState extends State<TextSelectionToolbar> {
  bool _showColorPicker = false;

  static const _actions = [
    _ToolbarAction(Icons.highlight, 'Highlight'),
    _ToolbarAction(Icons.note_add, 'Note'),
    _ToolbarAction(Icons.format_quote, 'Quote'),
    _ToolbarAction(Icons.copy, 'Copy'),
    _ToolbarAction(Icons.share, 'Share'),
  ];

  void _handleAction(int index) {
    switch (index) {
      case 0:
        // Highlight: toggle the color picker
        setState(() => _showColorPicker = !_showColorPicker);
        break;
      case 1:
        widget.onNote();
        widget.onDismiss();
        break;
      case 2:
        widget.onQuote();
        widget.onDismiss();
        break;
      case 3:
        if (widget.onCopy != null) {
          widget.onCopy!();
        } else {
          Clipboard.setData(ClipboardData(text: widget.selectedText));
        }
        widget.onDismiss();
        break;
      case 4:
        widget.onShare();
        widget.onDismiss();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Color picker (conditionally shown) ──
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _showColorPicker
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: HighlightColorPicker(
                      onColorSelected: (hex) {
                        widget.onHighlight(hex);
                        widget.onDismiss();
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Main toolbar ──
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_actions.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    return VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                    );
                  }
                  final action = _actions[i ~/ 2];
                  final index = i ~/ 2;
                  final isHighlight = index == 0 && _showColorPicker;
                  return _buildButton(
                    context,
                    action,
                    index,
                    isHighlight,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    _ToolbarAction action,
    int index,
    bool isActive,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => _handleAction(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 20,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 4),
            Text(
              action.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
