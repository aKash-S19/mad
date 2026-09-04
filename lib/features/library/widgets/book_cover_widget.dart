/// Reusable book cover widget for the Libora app.
///
/// Handles three cover sources with graceful fallback:
/// 1. Local file image ([coverPath])
/// 2. Remote network image ([coverUrl])
/// 3. Generated placeholder card with title + author
///
/// Shows a shimmer placeholder while the image loads, and a fallback
/// coloured card if the image fails to load or no source is available.
/// The cover maintains a 3:4 aspect ratio with rounded corners and
/// a subtle shadow for a premium, physical-book feel.
library;

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../data/models/book_model.dart';

class BookCoverWidget extends StatelessWidget {
  const BookCoverWidget({
    super.key,
    required this.book,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.showShadow = true,
    this.fit = BoxFit.cover,
  });

  /// The book whose cover should be displayed.
  final Book book;

  /// Optional explicit width. If null, the widget fills its parent constraints.
  final double? width;

  /// Optional explicit height. If null, a 3:4 aspect ratio is used.
  final double? height;

  /// Corner radius for the cover image.
  final double borderRadius;

  /// Whether to show a drop shadow beneath the cover.
  final bool showShadow;

  /// How the image should be inscribed into the available space.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasLocalCover =
        book.coverPath != null && book.coverPath!.isNotEmpty;
    final hasNetworkCover =
        book.coverUrl != null && book.coverUrl!.isNotEmpty;

    // Determine the actual size — either explicit or aspect-based.
    final double? effectiveWidth = width;
    final double? effectiveHeight = height;

    // Use aspect ratio 3:4 when neither dimension is explicit.
    Widget cover;

    if (hasLocalCover) {
      cover = _LocalCover(
        path: book.coverPath!,
        fit: fit,
        borderRadius: borderRadius,
        fallback: _FallbackCover(
          book: book,
          borderRadius: borderRadius,
          scheme: scheme,
          theme: theme,
        ),
      );
    } else if (hasNetworkCover) {
      cover = _NetworkCover(
        url: book.coverUrl!,
        fit: fit,
        borderRadius: borderRadius,
        fallback: _FallbackCover(
          book: book,
          borderRadius: borderRadius,
          scheme: scheme,
          theme: theme,
        ),
      );
    } else {
      cover = _FallbackCover(
        book: book,
        borderRadius: borderRadius,
        scheme: scheme,
        theme: theme,
      );
    }

    // Wrap with explicit sizing if provided.
    if (effectiveWidth != null || effectiveHeight != null) {
      cover = SizedBox(
        width: effectiveWidth,
        height: effectiveHeight,
        child: cover,
      );
    } else {
      // Default 3:4 aspect ratio.
      cover = AspectRatio(
        aspectRatio: 3 / 4,
        child: cover,
      );
    }

    // Add shadow for depth.
    if (showShadow) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: clipRounded(cover),
      );
    }

    return clipRounded(cover);
  }

  /// Clips the given child with rounded corners.
  Widget clipRounded(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }
}

// ── Local file cover ──────────────────────────────────────────────

class _LocalCover extends StatelessWidget {
  const _LocalCover({
    required this.path,
    required this.fit,
    required this.borderRadius,
    required this.fallback,
  });

  final String path;
  final BoxFit fit;
  final double borderRadius;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return fallback;
    }

    return Image.file(
      file,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return _ShimmerPlaceholder(borderRadius: borderRadius);
      },
    );
  }
}

// ── Network cover ─────────────────────────────────────────────────

class _NetworkCover extends StatelessWidget {
  const _NetworkCover({
    required this.url,
    required this.fit,
    required this.borderRadius,
    required this.fallback,
  });

  final String url;
  final BoxFit fit;
  final double borderRadius;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) =>
          _ShimmerPlaceholder(borderRadius: borderRadius),
      errorWidget: (context, url, error) => fallback,
    );
  }
}

// ── Fallback coloured cover with title + author ───────────────────

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({
    required this.book,
    required this.borderRadius,
    required this.scheme,
    required this.theme,
  });

  final Book book;
  final double borderRadius;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // Deterministic colour from the book title for visual consistency.
    final colours = [
      scheme.primary.withValues(alpha: 0.8),
      scheme.secondary.withValues(alpha: 0.7),
      scheme.tertiary.withValues(alpha: 0.7),
      scheme.primaryContainer,
      scheme.secondaryContainer,
    ];
    final colourIndex = book.title.hashCode.abs() % colours.length;
    final bgColour = colours[colourIndex];
    final onColour = _isLight(bgColour) ? Colors.black87 : Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColour,
            Color.lerp(bgColour, Colors.black, 0.15)!,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 24,
              color: onColour.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 6),
            Text(
              book.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: onColour,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            if (book.author.isNotEmpty)
              Text(
                book.author,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: onColour.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Returns true if the colour is light (so dark text is readable).
  bool _isLight(Color colour) {
    return colour.computeLuminance() > 0.5;
  }
}

// ── Shimmer placeholder ────────────────────────────────────────────

class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder({required this.borderRadius});

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColour = isDark
        ? Colors.grey.shade800
        : Colors.grey.shade300;
    final highlightColour = isDark
        ? Colors.grey.shade600
        : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColour,
      highlightColor: highlightColour,
      child: Container(
        decoration: BoxDecoration(
          color: baseColour,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
