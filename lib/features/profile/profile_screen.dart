/// Profile and Social screen for the Libora reading ecosystem.
///
/// Features Letterboxd-like profile sharing, reading statistics summary,
/// reading streak, reading goal, reading diary (rated and reviewed books),
/// favorite books, collections, saved quotes, and friends discovery.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:libora/core/router/app_router.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/providers/auth_provider.dart';
import 'package:libora/providers/library_provider.dart';
import 'package:libora/providers/profile_provider.dart';
import 'package:libora/providers/statistics_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _friendUsernameController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _friendUsernameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<ProfileProvider>().loadProfile(),
      context.read<StatisticsProvider>().loadStatistics(),
      context.read<LibraryProvider>().loadBooks(),
    ]);
  }

  void _shareProfile() {
    final text = context.read<ProfileProvider>().shareProfile();
    if (text.isNotEmpty) {
      Share.share(text);
    } else {
      Share.share(
          'Join me on Libora - your personal digital reading ecosystem!');
    }
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Reading Buddy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter their Libora username to connect and see what books they are reading.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _friendUsernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'e.g. bookworm42',
                prefixText: '@',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final username = _friendUsernameController.text.trim();
              if (username.isEmpty) return;
              Navigator.of(ctx).pop();
              final success =
                  await context.read<ProfileProvider>().addFriend(username);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Added @$username as reading buddy!'
                        : 'Could not find @$username.'),
                  ),
                );
              }
              _friendUsernameController.clear();
            },
            child: const Text('Add Friend'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final stats = context.watch<StatisticsProvider>();
    final library = context.watch<LibraryProvider>();

    final user = auth.currentUser;
    final displayName = user?.displayName ?? 'Avid Reader';
    final username = user?.username ?? 'reader';
    final isGuest = auth.isGuest || user == null;

    final completedBooks = library.books
        .where((b) => b.readingStatus == ReadingStatus.completed)
        .toList();
    final favoriteBooks = library.books
        .where((b) => b.readingStatus == ReadingStatus.favorite)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            tooltip: 'Reading Stats',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.statistics),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // ── User Header Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.5),
                    scheme.surfaceContainerLow,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: scheme.primary,
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'L',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@$username',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                            if (isGuest)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: scheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Guest Mode (Local Storage)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons: Share Profile + Add Friend
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _shareProfile,
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('Share Profile'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showAddFriendDialog,
                          icon: const Icon(Icons.person_add_outlined, size: 16),
                          label: const Text('Add Buddy'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Reading Stats Highlight (Letterboxd Vibe) ──
            Row(
              children: [
                _buildMetricCard(
                  'Completed',
                  '${completedBooks.length}',
                  Icons.done_all_rounded,
                  Colors.green,
                  scheme,
                ),
                const SizedBox(width: 10),
                _buildMetricCard(
                  'Streak',
                  '${stats.currentStreak}d 🔥',
                  Icons.local_fire_department,
                  Colors.orange,
                  scheme,
                ),
                const SizedBox(width: 10),
                _buildMetricCard(
                  'Quotes',
                  '${profile.savedQuotes.length}',
                  Icons.format_quote_rounded,
                  scheme.primary,
                  scheme,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Reading Goal Progress ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '2026 Reading Goal',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${completedBooks.length} / ${user?.readingGoal ?? 12} books',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ((completedBooks.length) /
                              (user?.readingGoal ?? 12))
                          .clamp(0.0, 1.0),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Quick Navigation Sections ──
            _buildNavTile(
              icon: Icons.favorite_rounded,
              iconColor: Colors.red,
              title: 'Favorite Books',
              subtitle: '${favoriteBooks.length} titles',
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.library);
              },
            ),
            _buildNavTile(
              icon: Icons.collections_bookmark_rounded,
              iconColor: Colors.blue,
              title: 'Custom Shelves & Collections',
              subtitle: '${profile.userCollections.length} collections',
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.collections);
              },
            ),
            _buildNavTile(
              icon: Icons.format_quote_rounded,
              iconColor: Colors.purple,
              title: 'Saved Quotes & Cards',
              subtitle: '${profile.savedQuotes.length} quotes',
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.quotes);
              },
            ),
            _buildNavTile(
              icon: Icons.highlight_rounded,
              iconColor: Colors.amber,
              title: 'Highlights Library',
              subtitle: 'Browse all saved passages',
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.highlights);
              },
            ),
            _buildNavTile(
              icon: Icons.note_alt_rounded,
              iconColor: Colors.teal,
              title: 'Personal Notes & Thoughts',
              subtitle: 'Browse book annotations',
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.notes);
              },
            ),

            const SizedBox(height: 32),

            // ── Account / Logout ──
            if (isGuest)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.login);
                },
                icon: const Icon(Icons.login),
                label: const Text('Login to Sync Profile with Cloud'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Log Out',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon,
      Color iconColor, ColorScheme scheme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
