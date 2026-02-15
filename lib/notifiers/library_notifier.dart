import 'package:ereader/models/book.dart';
import 'package:ereader/repositories/book_repository.dart';
import 'package:ereader/services/file_service.dart';
import 'package:ereader/utils/epub_parser.dart';
import 'package:flutter/foundation.dart';

/// Manages the book library state with persistence.
class LibraryNotifier extends ChangeNotifier {
  LibraryNotifier({
    required BookRepository bookRepository,
    required FileService fileService,
  }) : _bookRepository = bookRepository,
       _fileService = fileService;

  final BookRepository _bookRepository;
  final FileService _fileService;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;
  final List<Book> _books = [];

  List<Book> get books {
    final sorted = List<Book>.from(_books)
      ..sort((a, b) {
        // Books with lastReadAt come first, sorted by most recent
        if (a.lastReadAt != null && b.lastReadAt != null) {
          return b.lastReadAt!.compareTo(a.lastReadAt!);
        } else if (a.lastReadAt != null) {
          return -1; // a has been read, b hasn't -> a comes first
        } else if (b.lastReadAt != null) {
          return 1; // b has been read, a hasn't -> b comes first
        }
        // Both unread: sort by title
        return a.title.compareTo(b.title);
      });
    return List.unmodifiable(sorted);
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get initialized => _initialized;

  /// Initialize and load books from storage.
  Future<void> init() async {
    if (_initialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      final loadedBooks = await _bookRepository.loadBooks();
      _books.addAll(loadedBooks);

      _initialized = true;
    } on Exception catch (e) {
      _error = 'Failed to load library: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save books to storage.
  Future<void> _saveBooks() async {
    try {
      await _bookRepository.saveBooks(_books);
    } on Exception catch (e) {
      debugPrint('Failed to save books: $e');
    }
  }

  /// Adds a book by picking an EPUB file.
  Future<void> addBookFromPicker() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final files = await _fileService.pickEpubFiles();

      if (files != null && files.isNotEmpty) {
        final originalPath = files.first;

        // Copy file to app directory
        final savedPath = await _fileService.copyFileToAppDir(originalPath);

        // Check if book already exists (using filename for now, but path is unique)
        // With copied files, we should check if the original file was already imported
        // or just rely on title/author duplicates, but for now let's allow duplicates
        // since they are new files.
        // Or better: check if a book with same title/author exists?
        // For now, let's proceed with the saved path.

        final bookId = DateTime.now().millisecondsSinceEpoch.toString();

        // Extract metadata and cover image from the SAVED file
        final metadata = await EpubParser.parse(savedPath, bookId);

        final book = Book(
          id: bookId,
          title: metadata.title,
          filePath: savedPath,
          author: metadata.author,
          coverPath: metadata.coverPath,
        );

        _books.add(book);
        await _saveBooks();
      }
    } on Exception catch (e) {
      _error = 'Failed to add book: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Removes a book from the library.
  Future<void> removeBook(String bookId) async {
    final book = getBook(bookId);
    if (book != null) {
      // Delete cover image file
      await EpubParser.deleteCover(book.coverPath);
      // Delete book file
      await _fileService.deleteFile(book.filePath);
    }
    _books.removeWhere((book) => book.id == bookId);
    await _saveBooks();
    notifyListeners();
  }

  /// Updates a book's reading progress.
  Future<void> updateReadingProgress(
    String bookId,
    String cfi, {
    double progress = 0,
  }) async {
    final index = _books.indexWhere((book) => book.id == bookId);
    if (index != -1) {
      _books[index] = _books[index].copyWith(
        lastReadCfi: cfi,
        lastReadAt: DateTime.now(),
        progress: progress,
      );
      await _saveBooks();
      notifyListeners();
    }
  }

  /// Updates book metadata (title, author).
  Future<void> updateBookMetadata(
    String bookId, {
    String? title,
    String? author,
  }) async {
    final index = _books.indexWhere((book) => book.id == bookId);
    if (index != -1) {
      _books[index] = _books[index].copyWith(
        title: title,
        author: author,
      );
      await _saveBooks();
      notifyListeners();
    }
  }

  /// Updates book formatting preferences.
  Future<void> updateBookFormatting(
    String bookId, {
    double? fontSize,
    int? fontIndex,
    int? lineSpacingIndex,
    int? textAlignmentIndex,
  }) async {
    final index = _books.indexWhere((book) => book.id == bookId);
    if (index != -1) {
      _books[index] = _books[index].copyWith(
        fontSize: fontSize,
        fontIndex: fontIndex,
        lineSpacingIndex: lineSpacingIndex,
        textAlignmentIndex: textAlignmentIndex,
      );
      await _saveBooks();
      // Don't notify listeners for formatting changes to avoid rebuilds
    }
  }

  Book? getBook(String bookId) {
    final index = _books.indexWhere(
      (book) => book.id == bookId,
    );
    return index != -1 ? _books[index] : null;
  }
}
