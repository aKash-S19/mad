/// Quote Card Generator Screen for the Libora reading ecosystem.
///
/// Renders a shareable, visual card with Letterboxd-like typography and
/// styling. Allows toggling themes, font styles, and sharing via native share sheet.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/quote_model.dart';
import 'package:libora/providers/quotes_provider.dart';

enum QuoteCardTheme { midnight, sepia, crimson, minimal }

class QuoteCardScreen extends StatefulWidget {
  final String quoteId;

  const QuoteCardScreen({super.key, required this.quoteId});

  @override
  State<QuoteCardScreen> createState() => _QuoteCardScreenState();
}

class _QuoteCardScreenState extends State<QuoteCardScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  Quote? _quote;
  bool _isLoading = true;
  QuoteCardTheme _selectedTheme = QuoteCardTheme.midnight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuote();
    });
  }

  Future<void> _loadQuote() async {
    final quotesProvider = context.read<QuotesProvider>();
    Quote? quote = quotesProvider.quotes
        .where((q) => q.id == widget.quoteId)
        .firstOrNull;
    quote ??= await _db.getQuoteById(widget.quoteId);

    setState(() {
      _quote = quote;
      _isLoading = false;
    });
  }

  void _shareCard() {
    if (_quote == null) return;
    final q = _quote!;
    final text =
        '"${q.quoteText}"\n\n— ${q.author}\n${q.bookTitle} · Page ${q.page}\n\nREAD ON LIBORA';
    Share.share(text, subject: 'Quote from ${q.bookTitle}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_quote == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Quote not found')),
      );
    }

    final quote = _quote!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Card',
            onPressed: _shareCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Live Card Preview ──
            Center(
              child: _buildCardPreview(quote),
            ),

            const SizedBox(height: 32),

            // ── Theme Selector ──
            Text('Card Style', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _themeChip('Midnight', QuoteCardTheme.midnight,
                    const Color(0xFF16213E)),
                const SizedBox(width: 8),
                _themeChip('Sepia', QuoteCardTheme.sepia,
                    const Color(0xFFFBF0D9)),
                const SizedBox(width: 8),
                _themeChip('Crimson', QuoteCardTheme.crimson,
                    const Color(0xFF911F27)),
                const SizedBox(width: 8),
                _themeChip('Minimal', QuoteCardTheme.minimal,
                    Colors.white),
              ],
            ),

            const SizedBox(height: 36),

            // ── Share CTA Button ──
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _shareCard,
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Quote Card'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeChip(String label, QuoteCardTheme t, Color previewColor) {
    final isSelected = _selectedTheme == t;
    return ChoiceChip(
      avatar: CircleAvatar(
        radius: 8,
        backgroundColor: previewColor,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTheme = t),
    );
  }

  Widget _buildCardPreview(Quote quote) {
    Color bgGradient1;
    Color bgGradient2;
    Color textColor;
    Color authorColor;
    Color footerColor;
    Color accentBar;

    switch (_selectedTheme) {
      case QuoteCardTheme.midnight:
        bgGradient1 = const Color(0xFF1A1A2E);
        bgGradient2 = const Color(0xFF0F3460);
        textColor = Colors.white;
        authorColor = const Color(0xFFE94560);
        footerColor = Colors.white70;
        accentBar = const Color(0xFFE94560);
        break;
      case QuoteCardTheme.sepia:
        bgGradient1 = const Color(0xFFFBF0D9);
        bgGradient2 = const Color(0xFFEFE2C7);
        textColor = const Color(0xFF2C2013);
        authorColor = const Color(0xFF8D5B28);
        footerColor = const Color(0xFF5C4733);
        accentBar = const Color(0xFF8D5B28);
        break;
      case QuoteCardTheme.crimson:
        bgGradient1 = const Color(0xFF2B090F);
        bgGradient2 = const Color(0xFF5C1D24);
        textColor = Colors.white;
        authorColor = const Color(0xFFFF8E9E);
        footerColor = Colors.white70;
        accentBar = const Color(0xFFFF8E9E);
        break;
      case QuoteCardTheme.minimal:
        bgGradient1 = Colors.white;
        bgGradient2 = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF111111);
        authorColor = const Color(0xFF1976D2);
        footerColor = const Color(0xFF444444);
        accentBar = const Color(0xFF1976D2);
        break;
    }

    return Container(
      width: 340,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgGradient1, bgGradient2],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Accent Bar
            Container(height: 5, color: accentBar),

            // Card Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              child: Column(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 40,
                    color: authorColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 14),

                  // Quote Text
                  Text(
                    '"${quote.quoteText}"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Author
                  if (quote.author.isNotEmpty)
                    Text(
                      '— ${quote.author}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: authorColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Book & Page
                  if (quote.bookTitle.isNotEmpty)
                    Text(
                      '${quote.bookTitle}${quote.page > 0 ? " · p. ${quote.page}" : ""}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: footerColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  // Personal thought
                  if (quote.personalThought != null &&
                      quote.personalThought!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        quote.personalThought!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: footerColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Card Footer Branding (Letterboxd Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                border: Border(
                  top: BorderSide(
                    color: textColor.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories_rounded,
                          size: 16, color: authorColor),
                      const SizedBox(width: 6),
                      Text(
                        'READ ON LIBORA',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'libora.app',
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      color: footerColor,
                    ),
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
