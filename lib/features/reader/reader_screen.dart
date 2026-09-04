/// Reader screen for the Libora reading ecosystem.
///
/// An immersive, Kindle-like reading experience supporting PDF and EPUB files.
/// Features minimal controls that autohide, customizable reader appearance
/// (font size, font family, line spacing, margins, reading themes: Light,
/// Sepia, Dark, AMOLED), in-book text selection with contextual actions
/// (Highlight, Note, Quote, Copy, Share), Table of Contents, Bookmarks,
/// In-book Search, and persistent reading progress tracking.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:uuid/uuid.dart';

import 'package:libora/core/theme/reader_theme.dart' as rt;
import 'package:libora/data/database/database_helper.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/bookmark_model.dart';
import 'package:libora/data/models/chapter_model.dart';
import 'package:libora/data/models/highlight_model.dart';
import 'package:libora/data/models/note_model.dart';
import 'package:libora/data/models/quote_model.dart';
import 'package:libora/providers/highlights_provider.dart';
import 'package:libora/providers/library_provider.dart';
import 'package:libora/providers/notes_provider.dart';
import 'package:libora/providers/quotes_provider.dart';
import 'package:libora/providers/reader_provider.dart';
import 'package:libora/providers/settings_provider.dart';
import 'package:libora/services/epub_parser_service.dart';

import 'widgets/bookmarks_panel.dart';
import 'widgets/epub_content_view.dart';
import 'widgets/in_book_search_sheet.dart';
import 'widgets/note_editor_sheet.dart';
import 'widgets/reader_controls_bar.dart';
import 'widgets/reader_settings_sheet.dart';
import 'widgets/reader_top_bar.dart';
import 'widgets/text_selection_toolbar.dart';
import 'widgets/toc_panel.dart';

class ReaderScreen extends StatefulWidget {
  final String bookId;
  final int? initialChapterIndex;
  final int? initialPage;

  const ReaderScreen({
    super.key,
    required this.bookId,
    this.initialChapterIndex,
    this.initialPage,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final Uuid _uuid = const Uuid();
  final DatabaseHelper _db = DatabaseHelper.instance;

  PdfViewerController? _pdfController;
  Book? _book;
  bool _isLoading = true;
  String? _errorMessage;

  // EPUB State
  List<Chapter> _epubChapters = [];
  int _currentChapterIndex = 0;
  String _currentChapterHtml = '';
  bool _isLoadingChapter = false;

  // UI Panels State
  bool _isControlsVisible = true;
  bool _showTocPanel = false;
  bool _showBookmarksPanel = false;

  // Text Selection State
  String? _selectedText;
  Offset? _selectionPosition;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBook();
    });
  }

  @override
  void dispose() {
    _saveProgress();
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadBook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final library = context.read<LibraryProvider>();
      Book? book = await library.getBookById(widget.bookId);
      book ??= await _db.getBookById(widget.bookId);

      if (book == null) {
        setState(() {
          _errorMessage = 'Book not found.';
          _isLoading = false;
        });
        return;
      }

      _book = book;
      final reader = context.read<ReaderProvider>();
      await reader.openBook(book);

      // EPUB specific loading
      if (book.fileType == BookFileType.epub &&
          book.filePath != null &&
          File(book.filePath!).existsSync()) {
        try {
          final epubData = await EpubParserService.parseEpub(book.filePath!);
          _epubChapters = epubData.chapters;
          _currentChapterIndex = widget.initialChapterIndex ??
              (book.currentPage < _epubChapters.length
                  ? book.currentPage
                  : 0);

          if (_epubChapters.isNotEmpty) {
            await _loadChapterContent(_currentChapterIndex);
          }
        } catch (e) {
          debugPrint('ReaderScreen: EPUB parse error: $e');
        }
      }

      // If initial page is specified for PDF
      if (widget.initialPage != null && widget.initialPage! > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pdfController?.jumpToPage(widget.initialPage!);
        });
      } else if (book.currentPage > 0 && book.fileType == BookFileType.pdf) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pdfController?.jumpToPage(book!.currentPage + 1);
        });
      }

      // Mark as currently reading
      library.markAsReading(book.id);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load book: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChapterContent(int index) async {
    if (_book?.filePath == null) return;
    setState(() {
      _isLoadingChapter = true;
    });

    try {
      final html = await EpubParserService.extractChapterContent(
        _book!.filePath!,
        _epubChapters[index].href,
      );
      setState(() {
        _currentChapterIndex = index;
        _currentChapterHtml = html;
        _isLoadingChapter = false;
      });

      _updateProgress(
        index,
        _epubChapters.isNotEmpty
            ? (index + 1) / _epubChapters.length
            : 0.0,
      );
    } catch (e) {
      setState(() {
        _currentChapterHtml = '<p>Unable to load chapter content: $e</p>';
        _isLoadingChapter = false;
      });
    }
  }

  void _updateProgress(int page, double progress) {
    if (_book == null) return;
    context.read<ReaderProvider>().goToPage(page);
    context
        .read<LibraryProvider>()
        .updateReadingProgress(_book!.id, page, progress);
  }

  Future<void> _saveProgress() async {
    if (_book == null) return;
    final reader = context.read<ReaderProvider>();
    final currentPage = reader.currentPage;
    final totalPages = reader.totalPages > 0 ? reader.totalPages : 1;
    final progress = (currentPage + 1) / totalPages;
    await context
        .read<LibraryProvider>()
        .updateReadingProgress(_book!.id, currentPage, progress);
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
      if (!_isControlsVisible) {
        _selectedText = null;
        _showTocPanel = false;
        _showBookmarksPanel = false;
      }
    });
  }

  // ── Highlight, Note, Quote, Share handlers ──

  Future<void> _handleHighlight(String colorHex) async {
    if (_selectedText == null || _book == null) return;
    final text = _selectedText!;
    final reader = context.read<ReaderProvider>();

    final highlight = Highlight(
      id: _uuid.v4(),
      bookId: _book!.id,
      selectedText: text,
      color: colorHex,
      page: reader.currentPage + 1,
      chapter: _epubChapters.isNotEmpty &&
              _currentChapterIndex < _epubChapters.length
          ? _epubChapters[_currentChapterIndex].title
          : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await context.read<HighlightsProvider>().addHighlight(highlight);

    setState(() {
      _selectedText = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Highlight saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleNote() async {
    if (_selectedText == null || _book == null) return;
    final text = _selectedText!;
    final reader = context.read<ReaderProvider>();

    final noteContent = await NoteEditorSheet.show(
      context,
      selectedText: text,
      page: reader.currentPage + 1,
      chapter: _epubChapters.isNotEmpty &&
              _currentChapterIndex < _epubChapters.length
          ? _epubChapters[_currentChapterIndex].title
          : null,
    );

    if (noteContent != null && noteContent.trim().isNotEmpty) {
      final note = Note(
        id: _uuid.v4(),
        bookId: _book!.id,
        selectedText: text,
        content: noteContent.trim(),
        page: reader.currentPage + 1,
        chapter: _epubChapters.isNotEmpty &&
                _currentChapterIndex < _epubChapters.length
            ? _epubChapters[_currentChapterIndex].title
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await context.read<NotesProvider>().addNote(note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note attached to passage'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    setState(() {
      _selectedText = null;
    });
  }

  Future<void> _handleQuote() async {
    if (_selectedText == null || _book == null) return;
    final text = _selectedText!;
    final reader = context.read<ReaderProvider>();

    final quote = Quote(
      id: _uuid.v4(),
      bookId: _book!.id,
      bookTitle: _book!.title,
      author: _book!.author,
      quoteText: text,
      page: reader.currentPage + 1,
      chapter: _epubChapters.isNotEmpty &&
              _currentChapterIndex < _epubChapters.length
          ? _epubChapters[_currentChapterIndex].title
          : null,
      createdAt: DateTime.now(),
    );

    await context.read<QuotesProvider>().addQuote(quote);

    setState(() {
      _selectedText = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved to Quote Collection'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Create Card',
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/quote-card',
                arguments: quote.id,
              );
            },
          ),
        ),
      );
    }
  }

  void _handleShareText() {
    if (_selectedText == null) return;
    final title = _book?.title ?? '';
    final author = _book?.author ?? '';
    final text =
        '"$_selectedText"\n\n— $author, $title\n\nRead on Libora';
    Share.share(text);
    setState(() {
      _selectedText = null;
    });
  }

  Future<void> _addBookmark() async {
    if (_book == null) return;
    final reader = context.read<ReaderProvider>();
    final page = reader.currentPage + 1;
    await reader.addBookmark('Page $page');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bookmark added at page $page'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final reader = context.watch<ReaderProvider>();
    final themeColors =
        rt.ReaderTheme.forName(settings.readerTheme.name);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: themeColors.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: themeColors.accentColor),
        ),
      );
    }

    if (_errorMessage != null || _book == null) {
      return Scaffold(
        backgroundColor: themeColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: themeColors.textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: themeColors.textColor),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Unable to open book',
                  style: TextStyle(color: themeColors.textColor, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Library'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final book = _book!;

    return Scaffold(
      backgroundColor: themeColors.backgroundColor,
      body: Stack(
        children: [
          // ── Reading Content View ──
          GestureDetector(
            onTap: _toggleControls,
            child: book.fileType == BookFileType.epub
                ? _buildEpubViewer(settings, themeColors)
                : _buildPdfViewer(book, themeColors),
          ),

          // ── Top Control Bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ReaderTopBar(
              bookTitle: book.title,
              isVisible: _isControlsVisible,
              onBack: () {
                _saveProgress();
                Navigator.of(context).pop();
              },
              onTOC: () {
                setState(() {
                  _showTocPanel = !_showTocPanel;
                  _showBookmarksPanel = false;
                });
              },
              onBookmarks: () {
                setState(() {
                  _showBookmarksPanel = !_showBookmarksPanel;
                  _showTocPanel = false;
                });
              },
              onSearch: () {
                InBookSearchSheet.show(
                  context,
                  filePath: book.filePath,
                  chapters: _epubChapters,
                  onMatchSelected: (match) {
                    if (book.fileType == BookFileType.epub) {
                      _loadChapterContent(match.chapterIndex);
                    }
                  },
                );
              },
              onSettings: () => ReaderSettingsSheet.show(context),
              backgroundColor: themeColors.appBarColor,
              foregroundColor: themeColors.textColor,
            ),
          ),

          // ── Bottom Control Bar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ReaderControlsBar(
              currentPage: reader.currentPage,
              totalPages: book.fileType == BookFileType.epub
                  ? _epubChapters.length
                  : (reader.totalPages > 0
                      ? reader.totalPages
                      : (book.pageCount ?? 1)),
              isVisible: _isControlsVisible,
              onPageChanged: (newPage) {
                if (book.fileType == BookFileType.epub) {
                  _loadChapterContent(newPage);
                } else {
                  _pdfController?.jumpToPage(newPage + 1);
                }
              },
              onPreviousPage: () {
                if (book.fileType == BookFileType.epub) {
                  if (_currentChapterIndex > 0) {
                    _loadChapterContent(_currentChapterIndex - 1);
                  }
                } else {
                  _pdfController?.previousPage();
                }
              },
              onNextPage: () {
                if (book.fileType == BookFileType.epub) {
                  if (_currentChapterIndex < _epubChapters.length - 1) {
                    _loadChapterContent(_currentChapterIndex + 1);
                  }
                } else {
                  _pdfController?.nextPage();
                }
              },
              onSettings: () => ReaderSettingsSheet.show(context),
              backgroundColor: themeColors.appBarColor,
              foregroundColor: themeColors.textColor,
              accentColor: themeColors.accentColor,
            ),
          ),

          // ── Floating Text Selection Toolbar ──
          if (_selectedText != null && _selectedText!.trim().isNotEmpty)
            Positioned(
              top: _selectionPosition?.dy ?? 100,
              left: 20,
              right: 20,
              child: Center(
                child: TextSelectionToolbar(
                  selectedText: _selectedText!,
                  onHighlight: _handleHighlight,
                  onNote: _handleNote,
                  onQuote: _handleQuote,
                  onShare: _handleShareText,
                  onDismiss: () {
                    setState(() {
                      _selectedText = null;
                    });
                  },
                ),
              ),
            ),

          // ── Slide-in Table of Contents Panel ──
          if (_showTocPanel)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: TocPanel(
                chapters: _epubChapters,
                currentChapterIndex: _currentChapterIndex,
                onChapterSelected: (chapter) {
                  setState(() {
                    _showTocPanel = false;
                  });
                  final index = _epubChapters.indexOf(chapter);
                  if (index != -1) {
                    _loadChapterContent(index);
                  }
                },
                onClose: () {
                  setState(() {
                    _showTocPanel = false;
                  });
                },
                backgroundColor: themeColors.appBarColor,
                foregroundColor: themeColors.textColor,
                accentColor: themeColors.accentColor,
              ),
            ),

          // ── Slide-in Bookmarks Panel ──
          if (_showBookmarksPanel)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: BookmarksPanel(
                bookmarks: reader.bookmarks,
                currentPage: reader.currentPage,
                onBookmarkSelected: (b) {
                  setState(() {
                    _showBookmarksPanel = false;
                  });
                  if (book.fileType == BookFileType.epub) {
                    _loadChapterContent(b.page - 1);
                  } else {
                    _pdfController?.jumpToPage(b.page);
                  }
                },
                onAddBookmark: _addBookmark,
                onDeleteBookmark: (b) {
                  reader.deleteBookmark(b.id);
                },
                onClose: () {
                  setState(() {
                    _showBookmarksPanel = false;
                  });
                },
                backgroundColor: themeColors.appBarColor,
                foregroundColor: themeColors.textColor,
                accentColor: themeColors.accentColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEpubViewer(
      SettingsProvider settings, rt.ReaderThemeColors themeColors) {
    if (_isLoadingChapter) {
      return Center(
        child: CircularProgressIndicator(color: themeColors.accentColor),
      );
    }

    return SafeArea(
      child: EpubContentView(
        htmlContent: _currentChapterHtml.isNotEmpty
            ? _currentChapterHtml
            : '<h3>${_book?.title ?? ''}</h3><p>Chapter ${_currentChapterIndex + 1}</p>',
        themeColors: themeColors,
        fontSize: settings.fontSize,
        fontFamily: settings.fontFamily,
        lineSpacing: settings.lineSpacing,
        margins: settings.margins,
        textAlignment: settings.textAlignment,
        onTextSelected: (text) {
          setState(() {
            _selectedText = text;
            _selectionPosition = const Offset(0, 120);
          });
        },
        onPreviousChapter: () {
          if (_currentChapterIndex > 0) {
            _loadChapterContent(_currentChapterIndex - 1);
          }
        },
        onNextChapter: () {
          if (_currentChapterIndex < _epubChapters.length - 1) {
            _loadChapterContent(_currentChapterIndex + 1);
          }
        },
      ),
    );
  }

  Widget _buildPdfViewer(Book book, rt.ReaderThemeColors themeColors) {
    final filePath = book.filePath;
    final fileExists = filePath != null && File(filePath).existsSync();

    if (!fileExists) {
      // Fallback if local file not found
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf, size: 64, color: themeColors.textColor),
              const SizedBox(height: 16),
              Text(
                book.title,
                style: TextStyle(
                  color: themeColors.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'by ${book.author}',
                style: TextStyle(color: themeColors.textColor.withValues(alpha: 0.7), fontSize: 16),
              ),
              const SizedBox(height: 24),
              Text(
                'PDF file not located on device storage.\nIf this was imported from a temporary directory, please re-import the file.',
                style: TextStyle(color: themeColors.textColor.withValues(alpha: 0.7), height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SfPdfViewer.file(
      File(filePath),
      controller: _pdfController,
      canShowScrollHead: false,
      canShowScrollStatus: false,
      enableTextSelection: true,
      onDocumentLoaded: (details) {
        final total = details.document.pages.count;
        context.read<ReaderProvider>().setTotalPages(total);
      },
      onPageChanged: (details) {
        final page = details.newPageNumber - 1;
        final total = _pdfController?.pageCount ?? 1;
        _updateProgress(page, (page + 1) / total);
      },
      onTextSelectionChanged: (details) {
        if (details.selectedText != null &&
            details.selectedText!.trim().isNotEmpty) {
          setState(() {
            _selectedText = details.selectedText;
            _selectionPosition = const Offset(0, 100);
          });
        }
      },
    );
  }
}
