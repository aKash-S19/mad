/// Reading stats service for the Libora reading ecosystem.
///
/// Records and aggregates reading statistics: per-session metrics,
/// reading streaks, monthly/yearly breakdowns, and top authors.
/// Uses [DatabaseHelper] for all data persistence and retrieval.
library;

import 'package:flutter/foundation.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/reading_stats_model.dart';
import 'package:uuid/uuid.dart';

/// Daily aggregated reading stats.
class DailyStat {
  final DateTime date;
  final int pagesRead;
  final int readingTimeSeconds;

  const DailyStat({
    required this.date,
    this.pagesRead = 0,
    this.readingTimeSeconds = 0,
  });
}

/// Monthly aggregated reading stats.
class MonthlyStats {
  final int year;
  final int month;
  final int totalPagesRead;
  final int totalReadingTimeSeconds;
  final List<DailyStat> dailyStats;

  const MonthlyStats({
    required this.year,
    required this.month,
    this.totalPagesRead = 0,
    this.totalReadingTimeSeconds = 0,
    this.dailyStats = const [],
  });
}

/// Yearly aggregated reading stats.
class YearlyStats {
  final int year;
  final int totalPagesRead;
  final int totalReadingTimeSeconds;
  final List<MonthlyStats> monthlyStats;

  const YearlyStats({
    required this.year,
    this.totalPagesRead = 0,
    this.totalReadingTimeSeconds = 0,
    this.monthlyStats = const [],
  });
}

/// Author reading statistics.
class AuthorStat {
  final String author;
  final int bookCount;
  final int totalPagesRead;

  const AuthorStat({
    required this.author,
    this.bookCount = 0,
    this.totalPagesRead = 0,
  });
}

class ReadingStatsService {
  final DatabaseHelper _db = DatabaseHelper();
  static const Uuid _uuid = const Uuid();

  /// Records a reading session.
  ///
  /// Saves a [ReadingStats] entry with the given metrics. The [currentPage]
  /// is the position the reader reached during this session.
  Future<void> recordReadingSession(
    String bookId,
    int pagesRead,
    int durationSeconds,
    int currentPage,
  ) async {
    try {
      final stats = ReadingStats(
        id: _uuid.v4(),
        bookId: bookId,
        date: DateTime.now(),
        pagesRead: pagesRead,
        readingTimeSeconds: durationSeconds,
        currentPage: currentPage,
        sessionId: _uuid.v4(),
      );
      await _db.insertReadingStats(stats);
    } catch (e) {
      debugPrint('ReadingStatsService: recordReadingSession error: $e');
    }
  }

  /// Calculates the current reading streak (consecutive days with
  /// at least one reading session, counting backwards from today).
  Future<int> getReadingStreak() async {
    try {
      final allStats = await _db.getAllReadingStats();
      if (allStats.isEmpty) return 0;

      // Group by date (day only)
      final readingDays = <String>{};
      for (final stat in allStats) {
        final dateStr =
            stat.date.toIso8601String().substring(0, 10);
        readingDays.add(dateStr);
      }

      // Walk backwards from today
      int streak = 0;
      var current = DateTime.now();

      // If no reading today, start from yesterday
      final todayStr =
          current.toIso8601String().substring(0, 10);
      if (!readingDays.contains(todayStr)) {
        current = current.subtract(const Duration(days: 1));
      }

      while (true) {
        final dateStr =
            current.toIso8601String().substring(0, 10);
        if (readingDays.contains(dateStr)) {
          streak++;
          current = current.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('ReadingStatsService: getReadingStreak error: $e');
      return 0;
    }
  }

  /// Aggregates pages read and reading time per day for a given month.
  Future<MonthlyStats> getMonthlyStats(int year, int month) async {
    try {
      final startDate =
          DateTime(year, month, 1).toIso8601String();
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59)
          .toIso8601String();

      final stats = await _db.getReadingStatsByDateRange(
          startDate, endDate);

      // Aggregate by day
      final dailyMap = <int, DailyStat>{};
      int totalPages = 0;
      int totalTime = 0;

      for (final stat in stats) {
        final day = stat.date.day;
        final existing = dailyMap[day];
        if (existing != null) {
          dailyMap[day] = DailyStat(
            date: stat.date,
            pagesRead: existing.pagesRead + stat.pagesRead,
            readingTimeSeconds:
                existing.readingTimeSeconds +
                    stat.readingTimeSeconds,
          );
        } else {
          dailyMap[day] = DailyStat(
            date: stat.date,
            pagesRead: stat.pagesRead,
            readingTimeSeconds: stat.readingTimeSeconds,
          );
        }
        totalPages += stat.pagesRead;
        totalTime += stat.readingTimeSeconds;
      }

      return MonthlyStats(
        year: year,
        month: month,
        totalPagesRead: totalPages,
        totalReadingTimeSeconds: totalTime,
        dailyStats: dailyMap.values.toList()
          ..sort((a, b) => a.date.compareTo(b.date)),
      );
    } catch (e) {
      debugPrint('ReadingStatsService: getMonthlyStats error: $e');
      return MonthlyStats(year: year, month: month);
    }
  }

  /// Aggregates reading stats for an entire year, broken down by month.
  Future<YearlyStats> getYearlyStats(int year) async {
    try {
      final monthlyStats = <MonthlyStats>[];
      int totalPages = 0;
      int totalTime = 0;

      for (var month = 1; month <= 12; month++) {
        final monthly = await getMonthlyStats(year, month);
        monthlyStats.add(monthly);
        totalPages += monthly.totalPagesRead;
        totalTime += monthly.totalReadingTimeSeconds;
      }

      return YearlyStats(
        year: year,
        totalPagesRead: totalPages,
        totalReadingTimeSeconds: totalTime,
        monthlyStats: monthlyStats,
      );
    } catch (e) {
      debugPrint('ReadingStatsService: getYearlyStats error: $e');
      return YearlyStats(year: year);
    }
  }

  /// Returns the most-read authors ranked by book count.
  Future<List<AuthorStat>> getTopAuthors({int limit = 10}) async {
    try {
      final allBooks = await _db.getAllBooks();
      final authorMap = <String, int>{};

      for (final book in allBooks) {
        final author =
            book.author.isNotEmpty ? book.author : 'Unknown';
        authorMap[author] = (authorMap[author] ?? 0) + 1;
      }

      final stats = authorMap.entries
          .map((e) => AuthorStat(
                author: e.key,
                bookCount: e.value,
              ))
          .toList()
        ..sort((a, b) => b.bookCount.compareTo(a.bookCount));

      return stats.take(limit).toList();
    } catch (e) {
      debugPrint('ReadingStatsService: getTopAuthors error: $e');
      return [];
    }
  }

  /// Returns the total reading time across all sessions (in seconds).
  Future<int> getTotalReadingTime() async {
    try {
      final allStats = await _db.getAllReadingStats();
      return allStats.fold<int>(
          0, (sum, s) => sum + s.readingTimeSeconds);
    } catch (e) {
      debugPrint('ReadingStatsService: getTotalReadingTime error: $e');
      return 0;
    }
  }

  /// Returns the total pages read across all sessions.
  Future<int> getTotalPagesRead() async {
    try {
      final allStats = await _db.getAllReadingStats();
      return allStats.fold<int>(0, (sum, s) => sum + s.pagesRead);
    } catch (e) {
      debugPrint('ReadingStatsService: getTotalPagesRead error: $e');
      return 0;
    }
  }

  /// Returns reading stats for a specific book.
  Future<List<ReadingStats>> getStatsForBook(String bookId) async {
    try {
      return _db.getReadingStatsByBook(bookId);
    } catch (e) {
      debugPrint('ReadingStatsService: getStatsForBook error: $e');
      return [];
    }
  }

  /// Returns reading stats for a specific date.
  Future<List<ReadingStats>> getStatsForDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().substring(0, 10);
      return _db.getReadingStatsByDate(dateStr);
    } catch (e) {
      debugPrint('ReadingStatsService: getStatsForDate error: $e');
      return [];
    }
  }

  /// Returns the total reading time formatted as "Xh Ym".
  Future<String> getFormattedTotalReadingTime() async {
    final totalSeconds = await getTotalReadingTime();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
