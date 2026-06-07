import 'package:suvadi/models/book.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for managing Book persistence.
class BookRepository {
  BookRepository({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  /// Key for storing books in SharedPreferences.
  static const String _booksKey = 'library_books';

  /// Loads the list of books from persistent storage.
  List<Book> loadBooks() {
    final booksJson = _prefs.getString(_booksKey);

    if (booksJson != null && booksJson.isNotEmpty) {
      try {
        return Book.decodeBooks(booksJson);
      } on Exception {
        // Return empty list if parsing fails
        return [];
      }
    }
    return [];
  }

  /// Saves the list of books to persistent storage.
  Future<void> saveBooks(List<Book> books) async {
    final booksJson = Book.encodeBooks(books);
    await _prefs.setString(_booksKey, booksJson);
  }
}
