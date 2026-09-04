/// Date and time formatting utilities for Libora.
///
/// Uses [intl] for locale-aware formatting. All methods are static and
/// safe to call from anywhere (providers, widgets, models).
library;

import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// Formats a [DateTime] as e.g. "Sep 4, 2026".
  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  /// Formats a [DateTime] as e.g. "Sep 4, 2026 2:15 PM".
  static String formatDateTime(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  /// Formats a [DateTime] in ISO 8601 style: "2026-09-04 14:15".
  static String formatIso(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  /// Formats a [DateTime] as a short date with year: "09/04/2026".
  static String formatShort(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  /// Formats a time-of-day as "2:15 PM".
  static String formatTime(DateTime date) {
    return DateFormat.jm().format(date);
  }

  /// Returns a human-friendly relative string like "2 hours ago",
  /// "3 days ago", or "just now".
  static String formatRelativeTime(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(date);

    if (diff.isNegative) {
      // Future date — fall back to absolute formatting.
      return formatDate(date);
    }

    if (diff.inSeconds < 45) {
      return 'just now';
    }
    if (diff.inMinutes < 1) {
      return '${diff.inSeconds}s ago';
    }
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return '$w ${w == 1 ? 'week' : 'weeks'} ago';
    }
    if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      return '$mo ${mo == 1 ? 'month' : 'months'} ago';
    }
    final y = (diff.inDays / 365).floor();
    return '$y ${y == 1 ? 'year' : 'years'} ago';
  }

  /// Formats a date range like "Sep 4 – Sep 18, 2026".
  static String formatDateRange(DateTime start, DateTime end) {
    if (_sameDay(start, end)) {
      return formatDate(start);
    }
    if (start.year == end.year) {
      return '${DateFormat.MMMd().format(start)} – ${DateFormat.yMMMd().format(end)}';
    }
    return '${DateFormat.yMMMd().format(start)} – ${DateFormat.yMMMd().format(end)}';
  }

  /// Formats reading duration given as seconds into "2h 15m" (or
  /// "45m", "30s" for short reads).
  static String formatReadingTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) {
      return '${m}m';
    }
    if (m == 0) {
      return '${h}h';
    }
    return '${h}h ${m}m';
  }

  /// Like [formatReadingTime] but with a "reading time" suffix:
  /// e.g. "2h 15m read".
  static String formatReadingTimeLabelled(int seconds) {
    return '${formatReadingTime(seconds)} read';
  }

  /// Formats a calendar month for streak/header labels: "September 2026".
  static String formatMonthYear(DateTime date) {
    return DateFormat.yMMMM().format(date);
  }

  /// Formats a weekday name: "Monday".
  static String formatWeekday(DateTime date) {
    return DateFormat.EEEE().format(date);
  }

  /// Returns true if [a] and [b] fall on the same calendar day.
  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
