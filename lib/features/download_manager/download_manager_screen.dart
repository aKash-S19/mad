/// Download Manager Screen for the Libora reading ecosystem.
///
/// Tracks active book downloads, shows real-time progress percentages,
/// provides cancellation options, and lists completed downloads.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:libora/core/router/app_router.dart';
import 'package:libora/providers/download_provider.dart';
import 'package:libora/providers/library_provider.dart';

class DownloadManagerScreen extends StatelessWidget {
  const DownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final downloadProvider = context.watch<DownloadProvider>();
    final library = context.watch<LibraryProvider>();

    final activeEntries = downloadProvider.activeDownloads.entries.toList();
    final downloadedBooks =
        library.books.where((b) => b.isDownloaded).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads & Offline'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Active Downloads ──
          Text('Active Downloads (${activeEntries.length})',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (activeEntries.isEmpty)
            Card(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: Text(
                    'No active downloads right now.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ...activeEntries.map((entry) {
              final bookId = entry.key;
              final progress = entry.value;
              final percent = (progress * 100).toInt();

              return Card(
                elevation: 0,
                color: scheme.surfaceContainerLow,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Downloading book...',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined,
                                color: Colors.red),
                            onPressed: () {
                              downloadProvider.cancelDownload(bookId);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('$percent% completed',
                          style: TextStyle(
                              color: scheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 28),

          // ── Downloaded Books on Device ──
          Text('Downloaded on Device (${downloadedBooks.length})',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (downloadedBooks.isEmpty)
            Card(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Center(
                  child: Text(
                    'No downloaded books. Discover free books in the Browse tab to read offline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ...downloadedBooks.map((b) {
              return Card(
                elevation: 0,
                color: scheme.surfaceContainerLow,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                child: ListTile(
                  leading: const Icon(Icons.offline_pin, color: Colors.green),
                  title: Text(b.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(b.author,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.reader,
                        arguments: b.id,
                      );
                    },
                    child: const Text('Read'),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
