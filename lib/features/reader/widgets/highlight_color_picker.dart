/// Highlight color picker for the Libora reader.
///
/// A compact horizontal strip of selectable color swatches shown when the
/// user taps "Highlight" in the text-selection toolbar. The selected color
/// displays a check mark. Calls [onColorSelected] with the chosen hex string
/// (including the leading `#`).
library;

import 'package:flutter/material.dart';
import 'package:libora/core/constants/app_constants.dart';

class HighlightColorPicker extends StatefulWidget {
  /// The currently selected color (hex string, e.g. `#FFEB3B`).
  final String? selectedColor;

  /// Called when the user taps a swatch.
  final ValueChanged<String> onColorSelected;

  const HighlightColorPicker({
    super.key,
    this.selectedColor,
    required this.onColorSelected,
  });

  @override
  State<HighlightColorPicker> createState() => _HighlightColorPickerState();
}

class _HighlightColorPickerState extends State<HighlightColorPicker> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedColor;
  }

  @override
  void didUpdateWidget(covariant HighlightColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedColor != widget.selectedColor) {
      _selected = widget.selectedColor;
    }
  }

  static const List<({String label, String hex, Color color})> _colors = [
    (label: 'Yellow', hex: '#FFEB3B', color: Color(0xFFFFEB3B)),
    (label: 'Green', hex: '#4CAF50', color: Color(0xFF4CAF50)),
    (label: 'Blue', hex: '#2196F3', color: Color(0xFF2196F3)),
    (label: 'Pink', hex: '#E91E63', color: Color(0xFFE91E63)),
    (label: 'Purple', hex: '#AB47BC', color: Color(0xFFAB47BC)),
    (label: 'Orange', hex: '#FF9800', color: Color(0xFFFF9800)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _colors.map((entry) {
          final isSelected = _selected == entry.hex;
          return GestureDetector(
            onTap: () {
              setState(() => _selected = entry.hex);
              widget.onColorSelected(entry.hex);
            },
            child: Tooltip(
              message: entry.label,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: entry.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: entry.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
