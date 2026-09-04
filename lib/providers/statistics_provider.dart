/// Statistics provider for the Libora reading ecosystem.
///
/// Aggregates reading statistics: books completed, currently reading,
/// total pages read, total reading time, reading streak, monthly/yearly
/// breakdowns, and top authors. Queries the [DatabaseHelper] for raw data.
library;

import 'package:flutter/foundation.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/book_model.dart';

/// Monthly statistics for a single day.
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

/// Monthly statistics aggregating daily data.
class MonthlyStat {
  final int year;
  final int month;
  final int totalPagesRead;
  final int totalReadingTimeSeconds;
  final int booksCompleted;
  final List<DailyStat> dailyStats;

  const MonthlyStat({
    required this.year,
    required this.month,
    this.totalPagesRead = 0,
    this.totalReadingTimeSeconds = 0,
    this.booksCompleted = 0,
    this.dailyStats = const [],
  });
}

/// Yearly statistics aggregating monthly data.
class YearlyStat {
  final int year;
  final int totalPagesRead;
  final int totalReadingTimeSeconds;
  final int booksCompleted;
  final List<MonthlyStat> monthlyStats;

  const YearlyStat({
    required this.year,
    this.totalPagesRead = 0,
    this.totalReadingTimeSeconds = 0,
    this.booksCompleted = 0,
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

class StatisticsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  int _booksCompleted = 0;
  int get booksCompleted => _booksCompleted;

  int _booksCurrentlyReading = 0;
  int get booksCurrentlyReading => _booksCurrentlyReading;

  int _totalPagesRead = 0;
  int get totalPagesRead => _totalPagesRead;

  int _totalReadingTime = 0;
  int get totalReadingTime => _totalReadingTime;

  int _readingStreak = 0;
  int get readingStreak => _readingStreak;
  int get currentStreak => _readingStreak;

  int _totalHighlights = 0;
  int get totalHighlights => _totalHighlights;

  int _totalQuotes = 0;
  int get totalQuotes => _totalQuotes;

  List<AuthorStat> _topAuthors = [];
  List<AuthorStat> get topAuthors => _topAuthors;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Loads all statistics from the database.
  Future<void> loadStatistics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Books completed
      _booksCompleted =
          await _db.getBookCountByStatus(ReadingStatus.completed);

      // Books currently reading
      _booksCurrentlyReading = await _db
          .getBookCountByStatus(ReadingStatus.currentlyReading);

      // Total pages read and reading time from stats
      final allStats = await _db.getAllReadingStats();
      _totalPagesRead =
          allStats.fold(0, (sum, s) => sum + s.pagesRead);
      _totalReadingTime = allStats
          .fold(0, (sum, s) => sum + s.readingTimeSeconds);

      // Total highlights
      final recentHighlights =
          await _db.getRecentHighlights(limit: 10000);
      _totalHighlights = recentHighlights.length;

      // Total quotes
      final recentQuotes = await _db.getRecentQuotes(limit: 10000);
      _totalQuotes = recentQuotes.length;

      // Reading streak
      _readingStreak = await _calculateReadingStreak();

      // Top authors
      _topAuthors = await _getTopAuthors();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load statistics: $e';
      debugPrint('StatisticsProvider: loadStatistics error: $e');
      notifyListeners();
    }
  }

  /// Calculates the current reading streak (consecutive days with
  /// at least one reading session).
  Future<int> getReadingStreak() async {
    return _calculateReadingStreak();
  }

  Future<int> _calculateReadingStreak() async {
    try {
      final allStats = await _db.getAllReadingStats();
      if (allStats.isEmpty) return 0;

      // Group by date (day only)
      final readingDays = <String>{};
      for (final stat in allStats) {
        final dateStr = stat.date.toIso8601String().substring(0, 10);
        readingDays.add(dateStr);
      }

      // Walk backwards from today
      int streak = 0;
      var current = DateTime.now();

      // If no reading today, start from yesterday
      final todayStr = current.toIso8601String().substring(0, 10);
      if (!readingDays.contains(todayStr)) {
        current = current.subtract(const Duration(days: 1));
      }

      while (true) {
        final dateStr = current.toIso8601String().substring(0, 10);
        if (readingDays.contains(dateStr)) {
          streak++;
          current = current.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('StatisticsProvider: _calculateReadingStreak error: $e');
      return 0;
    }
  }

  /// Returns monthly statistics for a given year and month.
  Future<MonthlyStat> getMonthlyStats(int year, int month) async {
    try {
      final startDate =
          DateTime(year, month, 1).toIso8601String();
      final endDate =
          DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

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
            readingTimeSeconds: existing.readingTimeSeconds +
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

      // Books completed in this month
      final allBooks = await _db.getAllBooks();
      final booksCompleted = allBooks.where((b) {
        if (b.readingStatus != ReadingStatus.completed) return false;
        final completedDate = b.lastOpenedAt;
        if (completedDate == null) return false;
        return completedDate.year == year &&
            completedDate.month == month;
      }).length;

      return MonthlyStat(
        year: year,
        month: month,
        totalPagesRead: totalPages,
        totalReadingTimeSeconds: totalTime,
        booksCompleted: booksCompleted,
        dailyStats: dailyMap.values.toList()
          ..sort((a, b) => a.date.compareTo(b.date)),
      );
    } catch (e) {
      _error = 'Failed to get monthly stats: $e';
      debugPrint('StatisticsProvider: getMonthlyStats error: $e');
      notifyListeners();
      return MonthlyStat(year: year, month: month);
    }
  }

  /// Returns yearly statistics for a given year.
  Future<YearlyStat> getYearlyStats(int year) async {
    try {
      final monthlyStats = <MonthlyStat>[];
      int totalPages = 0;
      int totalTime = 0;
      int booksCompleted = 0;

      for (var month = 1; month <= 12; month++) {
        final monthly = await getMonthlyStats(year, month);
        monthlyStats.add(monthly);
        totalPages += monthly.totalPagesRead;
        totalTime += monthly.totalReadingTimeSeconds;
        booksCompleted += monthly.booksCompleted;
      }

      return YearlyStat(
        year: year,
        totalPagesRead: totalPages,
        totalReadingTimeSeconds: totalTime,
        booksCompleted: booksCompleted,
        monthlyStats: monthlyStats,
      );
    } catch (e) {
      _error = 'Failed to get yearly stats: $e';
      debugPrint('StatisticsProvider: getYearlyStats error: $e');
      notifyListeners();
      return YearlyStat(year: year);
    }
  }

  /// Returns the top authors by book count.
  Future<List<AuthorStat>> getTopAuthors() async {
    return _getTopAuthors();
  }

  Future<List<AuthorStat>> _getTopAuthors() async {
    try {
      final allBooks = await _db.getAllBooks();
      final authorMap = <String, int>{};

      for (final book in allBooks) {
        final author = book.author.isNotEmpty ? book.author : 'Unknown';
        authorMap[author] = (authorMap[author] ?? 0) + 1;
      }

      final stats = authorMap.entries
          .map((e) => AuthorStat(
                author: e.key,
                bookCount: e.value,
              ))
          .toList()
        ..sort((a, b) => b.bookCount.compareTo(a.bookCount));

      return stats.take(10).toList();
    } catch (e) {
      debugPrint('StatisticsProvider: _getTopAuthors error: $e');
      return [];
    }
  }

  /// Returns the total reading time formatted as "Xh Ym".
  String get formattedReadingTime {
    final hours = _totalReadingTime ~/ 3600;
    final minutes = (_totalReadingTime % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Returns the reading progress towards the annual goal.
  double getGoalProgress(int goal) {
    if (goal <= 0) return 0;
    return (_booksCompleted / goal).clamp(0.0, 1.0);
  }

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
