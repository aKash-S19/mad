/// Note editor bottom sheet for the Libora reader.
///
/// Shows the selected passage in a quote-styled box at the top, a text field
/// for the note content, and Cancel / Save buttons. Used both for creating a
/// new note and editing an existing one.
library;

import 'package:flutter/material.dart';

class NoteEditorSheet extends StatefulWidget {
  /// The selected passage to display above the editor (required).
  final String selectedText;

  /// Optional initial content when editing an existing note.
  final String? initialContent;

  /// Optional chapter name shown as context.
  final String? chapter;

  /// Optional page number shown as context.
  final int? page;

  /// Called when the user taps Save. Receives the note text.
  final ValueChanged<String> onSave;

  const NoteEditorSheet({
    super.key,
    required this.selectedText,
    this.initialContent,
    this.chapter,
    this.page,
    required this.onSave,
  });

  /// Convenience method to show this sheet as a modal bottom sheet.
  /// Returns the entered note text, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String selectedText,
    String? initialContent,
    String? chapter,
    int? page,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: NoteEditorSheet(
          selectedText: selectedText,
          initialContent: initialContent,
          chapter: chapter,
          page: page,
          onSave: (text) => Navigator.of(sheetContext).pop(text),
        ),
      ),
    );
  }

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent ?? '');
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Row(
            children: [
              Icon(Icons.edit_note, color: colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                widget.initialContent == null ? 'New Note' : 'Edit Note',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Selected passage ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: colorScheme.primary, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.chapter != null || widget.page != null) ...[
                  Text(
                    [
                      if (widget.chapter != null) widget.chapter!,
                      if (widget.page != null) 'p. ${widget.page}',
                    ].join(' \u00B7 '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  '\u201C${widget.selectedText}\u201D',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Text field ──
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 5,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Write your thoughts...',
              alignHintText: TextAlign.start,
            ),
          ),
          const SizedBox(height: 20),

          // ── Buttons ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    widget.onSave(text);
                  },
                  child: const Text('Save Note'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
