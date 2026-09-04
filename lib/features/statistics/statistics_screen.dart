/// Reading Statistics screen for the Libora reading ecosystem.
///
/// Presents clean, insightful metrics about the user's reading activity:
/// books completed, currently reading, pages read, reading streak,
/// reading hours, highlights, quotes, and top authors.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:libora/providers/statistics_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsProvider>().loadStatistics();
    });
  }

  String _formatReadingTime(int totalSeconds) {
    if (totalSeconds < 60) return '$totalSeconds sec';
    final minutes = totalSeconds ~/ 60;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    return '${hours}h ${remainingMins}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stats = context.watch<StatisticsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Analytics'),
      ),
      body: stats.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => stats.loadStatistics(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // ── Hero Streak Banner ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 56,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stats.readingStreak} Day Streak!',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stats.readingStreak > 0
                                    ? 'You read consecutively every day. Keep it going!'
                                    : 'Read a page today to start your reading streak.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text('Reading Summary', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // ── Metric Grid ──
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _buildStatCard(
                        title: 'Books Finished',
                        value: '${stats.booksCompleted}',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                        scheme: scheme,
                      ),
                      _buildStatCard(
                        title: 'Currently Reading',
                        value: '${stats.booksCurrentlyReading}',
                        icon: Icons.auto_stories,
                        color: scheme.primary,
                        scheme: scheme,
                      ),
                      _buildStatCard(
                        title: 'Pages Read',
                        value: '${stats.totalPagesRead}',
                        icon: Icons.pages_rounded,
                        color: Colors.blue,
                        scheme: scheme,
                      ),
                      _buildStatCard(
                        title: 'Reading Time',
                        value: _formatReadingTime(stats.totalReadingTime),
                        icon: Icons.timer_outlined,
                        color: Colors.purple,
                        scheme: scheme,
                      ),
                      _buildStatCard(
                        title: 'Highlights',
                        value: '${stats.totalHighlights}',
                        icon: Icons.highlight,
                        color: Colors.amber,
                        scheme: scheme,
                      ),
                      _buildStatCard(
                        title: 'Saved Quotes',
                        value: '${stats.totalQuotes}',
                        icon: Icons.format_quote,
                        color: Colors.pink,
                        scheme: scheme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Top Authors ──
                  if (stats.topAuthors.isNotEmpty) ...[
                    Text('Most Read Authors',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: scheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        children: stats.topAuthors.map((author) {
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                author.author.isNotEmpty
                                    ? author.author[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(author.author),
                            subtitle: Text('${author.bookCount} books'),
                            trailing: Text(
                              '${author.totalPagesRead} pages',
                              style: TextStyle(
                                  color: scheme.outline, fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ColorScheme scheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
