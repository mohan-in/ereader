import 'package:ereader/models/book.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for managing Book persistence.
class BookRepository {
  /// Key for storing books in SharedPreferences.
  static const String _booksKey = 'library_books';

  /// Loads the list of books from persistent storage.
  Future<List<Book>> loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final booksJson = prefs.getString(_booksKey);

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
    final prefs = await SharedPreferences.getInstance();
    final booksJson = Book.encodeBooks(books);
    await prefs.setString(_booksKey, booksJson);
  }
}
