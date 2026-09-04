/// EPUB chapter content renderer for the Libora reader.
///
/// Takes an HTML string from the [EpubParserService] and renders it as a
/// scrollable, formatted text view. Supports headings, paragraphs, bold,
/// italic, lists, and links. Applies reader settings (font size, line
/// spacing, margins, text color, background color). Supports text selection
/// so the reader can highlight/note/quote passages.
library;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:libora/core/theme/reader_theme.dart' as rt;
import 'package:libora/providers/settings_provider.dart';

class EpubContentView extends StatefulWidget {
  /// The HTML content to render.
  final String htmlContent;

  /// The reader theme colors to apply.
  final rt.ReaderThemeColors themeColors;

  /// Font size in logical pixels.
  final double fontSize;

  /// Font family key: 'Serif', 'Sans', or 'Mono'.
  final String fontFamily;

  /// Line spacing multiplier (1.0–2.5).
  final double lineSpacing;

  /// Horizontal margin in logical pixels.
  final double margins;

  /// Text alignment.
  final ReaderTextAlignment textAlignment;

  /// Called when text is selected by the user. Receives the selected text.
  final ValueChanged<String>? onTextSelected;

  /// Called when the user reaches the end of the chapter (scroll end).
  final VoidCallback? onChapterEnd;

  /// Called when the user swipes right (previous chapter).
  final VoidCallback? onPreviousChapter;

  /// Called when the user swipes left (next chapter).
  final VoidCallback? onNextChapter;

  const EpubContentView({
    super.key,
    required this.htmlContent,
    required this.themeColors,
    this.fontSize = 18.0,
    this.fontFamily = 'Serif',
    this.lineSpacing = 1.5,
    this.margins = 16.0,
    this.textAlignment = ReaderTextAlignment.justify,
    this.onTextSelected,
    this.onChapterEnd,
    this.onPreviousChapter,
    this.onNextChapter,
  });

  @override
  State<EpubContentView> createState() => _EpubContentViewState();
}

class _EpubContentViewState extends State<EpubContentView> {
  late final ScrollController _scrollController;
  List<_RenderNode> _nodes = [];
  String _selectedText = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _parseHtml();
  }

  @override
  void didUpdateWidget(covariant EpubContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      _parseHtml();
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _parseHtml() {
    final document = html_parser.parse(widget.htmlContent);
    final body = document.body;
    if (body == null) {
      _nodes = [];
      return;
    }
    _nodes = _buildNodes(body, 0);
  }

  List<_RenderNode> _buildNodes(html_dom.Node parent, int depth) {
    final nodes = <_RenderNode>[];
    for (final node in parent.nodes) {
      if (node is html_dom.Element) {
        final tag = node.localName?.toLowerCase() ?? '';
        switch (tag) {
          case 'h1':
          case 'h2':
          case 'h3':
          case 'h4':
          case 'h5':
          case 'h6':
            final level = int.tryParse(tag.substring(1)) ?? 3;
            nodes.add(_RenderNode.heading(
              text: _extractText(node),
              level: level,
            ));
            break;
          case 'p':
            nodes.add(_RenderNode.paragraph(
              spans: _buildInlineSpans(node),
            ));
            break;
          case 'ul':
          case 'ol':
            for (final li in node.children.where((e) =>
                e.localName?.toLowerCase() == 'li')) {
              nodes.add(_RenderNode.listItem(
                spans: _buildInlineSpans(li),
                ordered: tag == 'ol',
              ));
            }
            break;
          case 'blockquote':
            nodes.add(_RenderNode.blockquote(
              spans: _buildInlineSpans(node),
            ));
            break;
          case 'br':
            nodes.add(_RenderNode.spacing());
            break;
          case 'hr':
            nodes.add(_RenderNode.divider());
            break;
          case 'a':
            nodes.add(_RenderNode.paragraph(
              spans: _buildInlineSpans(node),
              isLink: true,
            ));
            break;
          default:
            // Recursively process unknown elements
            nodes.addAll(_buildNodes(node, depth + 1));
        }
      } else if (node is html_dom.Text) {
        final text = node.text.trim();
        if (text.isNotEmpty) {
          nodes.add(_RenderNode.paragraph(
            spans: [TextSpan(text: text)],
          ));
        }
      }
    }
    return nodes;
  }

  String _extractText(html_dom.Element element) {
    return element.text.trim();
  }

  List<TextSpan> _buildInlineSpans(html_dom.Node parent) {
    final spans = <TextSpan>[];
    for (final node in parent.nodes) {
      if (node is html_dom.Text) {
        final text = node.text;
        if (text.isNotEmpty) {
          spans.add(TextSpan(text: text));
        }
      } else if (node is html_dom.Element) {
        final tag = node.localName?.toLowerCase() ?? '';
        final childSpans = _buildInlineSpans(node);
        switch (tag) {
          case 'b':
          case 'strong':
            spans.add(TextSpan(
              children: childSpans,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ));
            break;
          case 'i':
          case 'em':
            spans.add(TextSpan(
              children: childSpans,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ));
            break;
          case 'u':
            spans.add(TextSpan(
              children: childSpans,
              style: const TextStyle(decoration: TextDecoration.underline),
            ));
            break;
          case 'a':
            final href = node.attributes['href'] ?? '';
            spans.add(TextSpan(
              children: childSpans,
              style: TextStyle(
                color: widget.themeColors.accentColor,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  if (href.isNotEmpty) {
                    // Could use url_launcher here
                    debugPrint('Link tapped: $href');
                  }
                },
            ));
            break;
          case 'br':
            spans.add(const TextSpan(text: '\n'));
            break;
          default:
            spans.addAll(childSpans);
        }
      }
    }
    return spans;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      widget.onChapterEnd?.call();
    }
  }

  TextAlign _mapAlignment(ReaderTextAlignment alignment) {
    switch (alignment) {
      case ReaderTextAlignment.left:
        return TextAlign.left;
      case ReaderTextAlignment.justify:
        return TextAlign.justify;
      case ReaderTextAlignment.center:
        return TextAlign.center;
    }
  }

  String? _resolveFontFamily() {
    switch (widget.fontFamily) {
      case 'Serif':
        return 'serif';
      case 'Mono':
        return 'monospace';
      default:
        return 'sans-serif';
    }
  }

  double _headingSizeForLevel(int level) {
    return switch (level) {
      1 => widget.fontSize + 12,
      2 => widget.fontSize + 8,
      3 => widget.fontSize + 5,
      4 => widget.fontSize + 3,
      _ => widget.fontSize + 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! > 200) {
          widget.onPreviousChapter?.call();
        } else if (details.primaryVelocity! < -200) {
          widget.onNextChapter?.call();
        }
      },
      child: SelectionArea(
        onSelectionChanged: (selection) {
          _selectedText = selection?.plainText ?? '';
          if (_selectedText.isNotEmpty) {
            widget.onTextSelected?.call(_selectedText);
          }
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: widget.margins,
            vertical: widget.margins + 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _nodes.map((node) => _buildNodeWidget(node)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeWidget(_RenderNode node) {
    final textColor = widget.themeColors.textColor;
    final fontFamily = _resolveFontFamily();

    switch (node.type) {
      case _NodeType.heading:
        return Padding(
          padding: EdgeInsets.only(
            top: node.level <= 2 ? 24.0 : 16.0,
            bottom: 8.0,
          ),
          child: Text(
            node.text ?? '',
            style: TextStyle(
              fontSize: _headingSizeForLevel(node.level),
              fontWeight: FontWeight.w600,
              color: textColor,
              height: widget.lineSpacing * 1.1,
              fontFamily: fontFamily,
            ),
            textAlign: _mapAlignment(widget.textAlignment),
          ),
        );

      case _NodeType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RichText(
            text: TextSpan(
              children: node.spans,
              style: TextStyle(
                fontSize: widget.fontSize,
                color: textColor,
                height: widget.lineSpacing,
                fontFamily: fontFamily,
                letterSpacing: 0.2,
              ),
            ),
            textAlign: _mapAlignment(widget.textAlignment),
          ),
        );

      case _NodeType.listItem:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.ordered ? '\u2022' : '\u2022',
                style: TextStyle(
                  fontSize: widget.fontSize,
                  color: textColor,
                  height: widget.lineSpacing,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: node.spans,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      color: textColor,
                      height: widget.lineSpacing,
                      fontFamily: fontFamily,
                    ),
                  ),
                  textAlign: _mapAlignment(widget.textAlignment),
                ),
              ),
            ],
          ),
        );

      case _NodeType.blockquote:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: widget.themeColors.accentColor,
                width: 3,
              ),
            ),
          ),
          child: RichText(
            text: TextSpan(
              children: node.spans,
              style: TextStyle(
                fontSize: widget.fontSize,
                color: textColor.withValues(alpha: 0.85),
                height: widget.lineSpacing,
                fontStyle: FontStyle.italic,
                fontFamily: fontFamily,
              ),
            ),
            textAlign: _mapAlignment(widget.textAlignment),
          ),
        );

      case _NodeType.spacing:
        return const SizedBox(height: 16);

      case _NodeType.divider:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Divider(
            color: textColor.withValues(alpha: 0.2),
            thickness: 0.5,
          ),
        );
    }
  }
}

// ── Internal render model ──

enum _NodeType {
  heading,
  paragraph,
  listItem,
  blockquote,
  spacing,
  divider,
}

class _RenderNode {
  final _NodeType type;
  final String? text;
  final List<TextSpan> spans;
  final int level;
  final bool ordered;
  final bool isLink;

  const _RenderNode._({
    required this.type,
    this.text,
    this.spans = const [],
    this.level = 0,
    this.ordered = false,
    this.isLink = false,
  });

  factory _RenderNode.heading({required String text, required int level}) =>
      _RenderNode._(type: _NodeType.heading, text: text, level: level);

  factory _RenderNode.paragraph({
    required List<TextSpan> spans,
    bool isLink = false,
  }) =>
      _RenderNode._(
        type: _NodeType.paragraph,
        spans: spans,
        isLink: isLink,
      );

  factory _RenderNode.listItem({
    required List<TextSpan> spans,
    required bool ordered,
  }) =>
      _RenderNode._(
        type: _NodeType.listItem,
        spans: spans,
        ordered: ordered,
      );

  factory _RenderNode.blockquote({required List<TextSpan> spans}) =>
      _RenderNode._(type: _NodeType.blockquote, spans: spans);

  factory _RenderNode.spacing() => const _RenderNode._(type: _NodeType.spacing);

  factory _RenderNode.divider() => const _RenderNode._(type: _NodeType.divider);
}
