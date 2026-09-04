/// Quote card service for the Libora reading ecosystem.
///
/// Generates a polished, shareable quote card widget that renders the
/// quote text, author, book title, page number, and "READ ON LIBORA"
/// branding. The returned widget can be captured with [RepaintBoundary]
/// and converted to an image for sharing via [share_plus].
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libora/data/models/quote_model.dart';

class QuoteCardService {
  /// Generates a beautiful quote card widget from a [Quote].
  ///
  /// The card has a modern, polished design suitable for sharing on
  /// social media. It includes:
  /// - The quote text in an elegant serif font
  /// - The author and book title below
  /// - The page number
  /// - "READ ON LIBORA" branding at the bottom
  ///
  /// Wrap the returned widget in a [RepaintBoundary] and use
  /// `RenderRepaintBoundary.toImage()` to capture it as an image.
  Widget generateQuoteCard(Quote quote, {double width = 400}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative top bar
            Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE94560),
                    Color(0xFF0F3460),
                    Color(0xFFE94560),
                  ],
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Opening quotation mark
                  Icon(
                    Icons.format_quote,
                    color: const Color(0xFFE94560)
                        .withValues(alpha: 0.8),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  // Quote text
                  Text(
                    '"${quote.quoteText}"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Author
                  if (quote.author.isNotEmpty)
                    Text(
                      '— ${quote.author}',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE94560),
                        letterSpacing: 1.2,
                      ),
                    ),
                  const SizedBox(height: 6),
                  // Book title and page
                  if (quote.bookTitle.isNotEmpty)
                    Text(
                      '${quote.bookTitle}${quote.page > 0 ? ' · p. ${quote.page}' : ''}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: Colors.white54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  // Personal thought if present
                  if (quote.personalThought != null &&
                      quote.personalThought!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white12,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        quote.personalThought!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          height: 1.5,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Branding footer
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                border: Border(
                  top: BorderSide(
                    color: Colors.white
                        .withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 16,
                        color: const Color(0xFFE94560),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'READ ON LIBORA',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatDate(quote.createdAt),
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.white38,
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

  /// Formats a date as "MMM yyyy" (e.g., "Sep 2026").
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
