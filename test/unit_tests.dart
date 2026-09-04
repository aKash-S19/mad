import 'package:flutter_test/flutter_test.dart';
import 'package:libora/data/models/book_model.dart';
import 'package:libora/data/models/highlight_model.dart';
import 'package:libora/data/models/quote_model.dart';
import 'package:libora/core/utils/date_formatter.dart';
import 'package:libora/core/utils/validators.dart';
import 'package:libora/core/theme/reader_theme.dart' as rt;

void main() {
  group('Book Model Tests', () {
    test('Book model instantiation and serialization', () {
      final now = DateTime.now();
      final book = Book(
        id: 'book_123',
        title: 'Meditations',
        author: 'Marcus Aurelius',
        description: 'Personal writings on Stoic philosophy',
        fileType: BookFileType.epub,
        fileSize: 1024000,
        pageCount: 250,
        currentPage: 42,
        readingProgress: 0.168,
        readingStatus: ReadingStatus.currentlyReading,
        addedAt: now,
      );

      expect(book.id, 'book_123');
      expect(book.title, 'Meditations');
      expect(book.author, 'Marcus Aurelius');
      expect(book.fileType, BookFileType.epub);
      expect(book.readingStatus, ReadingStatus.currentlyReading);
      expect(book.currentPage, 42);

      final map = book.toMap();
      expect(map['id'], 'book_123');
      expect(map['title'], 'Meditations');
      expect(map['file_type'], 'epub');

      final fromMap = Book.fromMap(map);
      expect(fromMap.id, book.id);
      expect(fromMap.title, book.title);
      expect(fromMap.author, book.author);
      expect(fromMap.fileType, book.fileType);
      expect(fromMap.readingStatus, book.readingStatus);
    });

    test('Book status enum conversion works correctly', () {
      expect(ReadingStatusX.fromString('wantToRead'), ReadingStatus.wantToRead);
      expect(ReadingStatusX.fromString('currentlyReading'), ReadingStatus.currentlyReading);
      expect(ReadingStatusX.fromString('completed'), ReadingStatus.completed);
      expect(ReadingStatusX.fromString('favorite'), ReadingStatus.favorite);
      expect(ReadingStatusX.fromString('unknown'), ReadingStatus.wantToRead);
    });
  });

  group('Highlight & Quote Model Tests', () {
    test('Highlight model serialization', () {
      final now = DateTime.now();
      final highlight = Highlight(
        id: 'hl_1',
        bookId: 'book_123',
        selectedText: 'The obstacle is the way.',
        color: '#FFEB3B',
        page: 15,
        chapter: 'Book IV',
        createdAt: now,
        updatedAt: now,
      );

      final map = highlight.toMap();
      expect(map['id'], 'hl_1');
      expect(map['selected_text'], 'The obstacle is the way.');
      expect(map['color'], '#FFEB3B');
      expect(map['page'], 15);

      final fromMap = Highlight.fromMap(map);
      expect(fromMap.id, highlight.id);
      expect(fromMap.selectedText, highlight.selectedText);
    });

    test('Quote model serialization', () {
      final now = DateTime.now();
      final quote = Quote(
        id: 'q_1',
        bookId: 'book_123',
        bookTitle: 'Meditations',
        author: 'Marcus Aurelius',
        quoteText: 'You have power over your mind - not outside events.',
        page: 88,
        isFavorite: true,
        createdAt: now,
      );

      final map = quote.toMap();
      expect(map['id'], 'q_1');
      expect(map['quote_text'], 'You have power over your mind - not outside events.');
      expect(map['is_favorite'], 1);

      final fromMap = Quote.fromMap(map);
      expect(fromMap.id, quote.id);
      expect(fromMap.isFavorite, true);
    });
  });

  group('Utility & Validator Tests', () {
    test('Email validator handles valid and invalid emails', () {
      expect(Validators.validateEmail('user@example.com'), null);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('Password validator enforces minimum length', () {
      expect(Validators.validatePassword('123456'), null);
      expect(Validators.validatePassword('123'), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('DateFormatter formats dates and relative times', () {
      final pastDate = DateTime.now().subtract(const Duration(minutes: 5));
      final relative = DateFormatter.formatRelativeTime(pastDate);
      expect(relative.isNotEmpty, true);
    });
  });

  group('Reader Theme Tests', () {
    test('ReaderThemeColors generates correct colors for all themes', () {
      final light = rt.ReaderTheme.forName('light');
      expect(light.backgroundColor, isNotNull);

      final sepia = rt.ReaderTheme.forName('sepia');
      expect(sepia.backgroundColor, isNotNull);

      final dark = rt.ReaderTheme.forName('dark');
      expect(dark.backgroundColor, isNotNull);

      final amoled = rt.ReaderTheme.forName('amoled');
      expect(amoled.backgroundColor, const Color(0xFF000000));
    });
  });
}
