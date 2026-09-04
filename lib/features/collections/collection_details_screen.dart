/// Collection Details screen for viewing books within a custom shelf.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:libora/core/router/app_router.dart';
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/collection_model.dart';
import 'package:libora/features/library/widgets/book_grid_card.dart';
import 'package:libora/features/library/widgets/book_list_tile.dart';
import 'package:libora/providers/collections_provider.dart';
import 'package:libora/providers/library_provider.dart';

class CollectionDetailsScreen extends StatefulWidget {
  final String collectionId;

  const CollectionDetailsScreen({super.key, required this.collectionId});

  @override
  State<CollectionDetailsScreen> createState() =>
      _CollectionDetailsScreenState();
}

class _CollectionDetailsScreenState extends State<CollectionDetailsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  Collection? _collection;
  List<Book> _books = [];
  bool _isLoading = true;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCollectionBooks();
    });
  }

  Future<void> _loadCollectionBooks() async {
    setState(() => _isLoading = true);

    try {
      final cp = context.read<CollectionsProvider>();
      final col = await cp.getCollectionById(widget.collectionId);
      final books =
          await _db.getBooksForCollection(widget.collectionId);

      setState(() {
        _collection = col;
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('CollectionDetailsScreen error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddBooksModal() {
    final library = context.read<LibraryProvider>();
    final availableBooks = library.books
        .where((b) => !_books.any((cb) => cb.id == b.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Books to Shelf',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (availableBooks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'All books in your library are already in this shelf!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              SizedBox(
                height: 350,
                child: ListView.builder(
                  itemCount: availableBooks.length,
                  itemBuilder: (context, index) {
                    final book = availableBooks[index];
                    return ListTile(
                      title: Text(book.title),
                      subtitle: Text(book.author),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: () async {
                          await context
                              .read<CollectionsProvider>()
                              .addBookToCollection(
                                  widget.collectionId, book.id);
                          Navigator.of(ctx).pop();
                          _loadCollectionBooks();
                        },
                      ),
                    );
                  },
                ),
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final title = _collection?.name ?? 'Collection';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'List View' : 'Grid View',
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Book',
            onPressed: _showAddBooksModal,
          ),
        ],
      ),
      body: _books.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shelves, size: 64, color: scheme.outline),
                    const SizedBox(height: 16),
                    Text('This shelf is empty',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text(
                      'Add books from your library to keep them grouped here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      onPressed: _showAddBooksModal,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Books'),
                    ),
                  ],
                ),
              ),
            )
          : _isGridView
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return BookGridCard(
                      book: book,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRouter.bookDetails,
                          arguments: book.id,
                        );
                      },
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _books.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return BookListTile(
                      book: book,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRouter.bookDetails,
                          arguments: book.id,
                        );
                      },
                    );
                  },
                ),
    );
  }
}
