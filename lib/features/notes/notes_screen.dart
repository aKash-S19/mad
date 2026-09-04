/// Notes Library screen for the Libora reading ecosystem.
///
/// A dedicated knowledge archive allowing users to browse, search, edit,
/// and revisit personal annotations attached to specific passages.
/// Tapping a note immediately opens the reader at that exact position.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:libora/core/router/app_router.dart';
import 'package:libora/core/utils/date_formatter.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/note_model.dart';
import 'package:libora/features/reader/widgets/note_editor_sheet.dart';
import 'package:libora/providers/notes_provider.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Book> _books = [];
  String? _selectedBookId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final notesProvider = context.read<NotesProvider>();
    await notesProvider.loadNotes();
    final books = await _db.getAllBooks();
    setState(() {
      _books = books;
    });
  }

  void _editNote(Note note) async {
    final updatedText = await NoteEditorSheet.show(
      context,
      selectedText: note.selectedText,
      initialContent: note.content,
      page: note.page,
      chapter: note.chapter,
    );

    if (updatedText != null && updatedText.trim().isNotEmpty && mounted) {
      await context.read<NotesProvider>().updateNote(
            note.copyWith(
              content: updatedText.trim(),
              updatedAt: DateTime.now(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final notesProvider = context.watch<NotesProvider>();

    var notes = notesProvider.notes;
    if (_selectedBookId != null) {
      notes = notes.where((n) => n.bookId == _selectedBookId).toList();
    }
    if (_searchController.text.trim().isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      notes = notes
          .where((n) =>
              n.content.toLowerCase().contains(q) ||
              n.selectedText.toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Archive'),
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search notes and annotations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Book Filter Chips ──
          if (_books.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChip(
                    label: const Text('All Books'),
                    selected: _selectedBookId == null,
                    onSelected: (_) => setState(() => _selectedBookId = null),
                  ),
                  const SizedBox(width: 8),
                  ..._books.map((b) {
                    final isSelected = b.id == _selectedBookId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(b.title, maxLines: 1),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedBookId = isSelected ? null : b.id;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── Notes List ──
          Expanded(
            child: notesProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : notes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.note_alt_outlined,
                                  size: 64, color: scheme.outline),
                              const SizedBox(height: 16),
                              Text('No Notes Created',
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(
                                'Add personal thoughts to passages while reading any book to build your personal knowledge base.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final n = notes[index];
                          final book = _books
                              .where((b) => b.id == n.bookId)
                              .firstOrNull;
                          final bookTitle = book?.title ?? 'Unknown Book';

                          return Card(
                            elevation: 0,
                            color: scheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: scheme.outlineVariant),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: Book Title & Page
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          bookTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Page ${n.page}',
                                        style: TextStyle(
                                          color: scheme.outline,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Personal Note
                                  Text(
                                    n.content,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Selected Passage Box
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border(
                                        left: BorderSide(
                                          color: scheme.primary,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '"${n.selectedText}"',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: scheme.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Footer with Actions
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormatter.formatRelativeTime(
                                            n.updatedAt),
                                        style: TextStyle(
                                          color: scheme.outline,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined,
                                                size: 18),
                                            tooltip: 'Edit Note',
                                            onPressed: () => _editNote(n),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18),
                                            tooltip: 'Delete',
                                            onPressed: () {
                                              notesProvider.deleteNote(n.id);
                                            },
                                          ),
                                          FilledButton.tonalIcon(
                                            onPressed: () {
                                              Navigator.of(context).pushNamed(
                                                AppRouter.reader,
                                                arguments: {
                                                  'bookId': n.bookId,
                                                  'page': n.page - 1,
                                                },
                                              );
                                            },
                                            icon: const Icon(
                                                Icons.arrow_forward,
                                                size: 14),
                                            label: const Text('Read'),
                                            style: FilledButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
