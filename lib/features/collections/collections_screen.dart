/// Collections Screen for managing user bookshelves.
///
/// Enables users to create, rename, delete, and organize custom shelves
/// such as Philosophy, Programming, Psychology, Favorites, and 2026 Reading.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:libora/core/router/app_router.dart';
import 'package:libora/data/models/collection_model.dart';
import 'package:libora/providers/collections_provider.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final List<String> _colorPalette = [
    '#1976D2', // Blue
    '#388E3C', // Green
    '#7B1FA2', // Purple
    '#D32F2F', // Red
    '#E65100', // Orange
    '#00796B', // Teal
    '#455A64', // Blue Grey
  ];
  String _selectedColor = '#1976D2';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectionsProvider>().loadCollections();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showCreateCollectionDialog({Collection? existing}) {
    if (existing != null) {
      _nameController.text = existing.name;
      _descController.text = existing.description;
      _selectedColor = existing.color;
    } else {
      _nameController.clear();
      _descController.clear();
      _selectedColor = _colorPalette.first;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Shelf' : 'Create New Shelf'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Shelf Name',
                    hintText: 'e.g. Philosophy, 2026 Reading',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Shelf Color',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _colorPalette.map((c) {
                    final colorVal =
                        Color(int.parse(c.replaceFirst('#', '0xFF')));
                    final isSelected = _selectedColor == c;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => _selectedColor = c);
                      },
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: colorVal,
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop();

                final cp = context.read<CollectionsProvider>();
                if (existing != null) {
                  await cp.updateCollection(
                    existing.copyWith(
                      name: name,
                      description: _descController.text.trim(),
                      color: _selectedColor,
                    ),
                  );
                } else {
                  await cp.createCollection(
                    name,
                    description: _descController.text.trim(),
                    color: _selectedColor,
                  );
                }
              },
              child: Text(existing != null ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cp = context.watch<CollectionsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Shelves'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCollectionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Shelf'),
      ),
      body: cp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cp.collections.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shelves, size: 64, color: scheme.outline),
                        const SizedBox(height: 16),
                        Text('No Shelves Created',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Organize your books into custom categories like Philosophy, Programming, or 2026 Goals.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.tonalIcon(
                          onPressed: () => _showCreateCollectionDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Shelf'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: cp.collections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final col = cp.collections[index];
                    final colorVal = Color(
                        int.parse(col.color.replaceFirst('#', '0xFF')));

                    return Card(
                      elevation: 0,
                      color: scheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorVal.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.collections_bookmark_rounded,
                              color: colorVal),
                        ),
                        title: Text(col.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          col.description.isNotEmpty
                              ? '${col.description}\n${col.bookCount} books'
                              : '${col.bookCount} books',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showCreateCollectionDialog(existing: col);
                            } else if (val == 'delete') {
                              cp.deleteCollection(col.id);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Rename / Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRouter.collectionDetails,
                            arguments: col.id,
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
