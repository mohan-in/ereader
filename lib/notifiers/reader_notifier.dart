import 'package:flutter/foundation.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../models/book.dart';

/// Available fonts for the reader.
enum ReaderFont {
  defaultFont('Default', 'serif'),
  sansSerif('Sans Serif', 'sans-serif'),
  roboto('Roboto', 'Roboto, sans-serif'),
  georgia('Georgia', 'Georgia, serif'),
  openDyslexic('OpenDyslexic', 'OpenDyslexic, sans-serif');

  final String displayName;
  final String fontFamily;

  const ReaderFont(this.displayName, this.fontFamily);
}

/// Manages the EPUB reader state.
class ReaderNotifier extends ChangeNotifier {
  Book? _currentBook;
  List<EpubChapter> _chapters = [];
  EpubLocation? _currentLocation;
  bool _isLoading = false;
  double _fontSize = 16.0;
  ReaderFont _font = ReaderFont.defaultFont;
  String? _error;

  Book? get currentBook => _currentBook;
  List<EpubChapter> get chapters => _chapters;
  EpubLocation? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  double get fontSize => _fontSize;
  ReaderFont get font => _font;
  String? get error => _error;

  /// Sets the current book to read.
  void setCurrentBook(Book book) {
    _currentBook = book;
    _chapters = [];
    _currentLocation = null;
    _error = null;
    notifyListeners();
  }

  /// Updates the chapters list.
  void setChapters(List<EpubChapter> chapters) {
    _chapters = chapters;
    notifyListeners();
  }

  /// Updates the current reading location.
  void setCurrentLocation(EpubLocation location) {
    _currentLocation = location;
    notifyListeners();
  }

  /// Sets loading state.
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Updates font size.
  void setFontSize(double size) {
    _fontSize = size.clamp(12.0, 28.0);
    notifyListeners();
  }

  /// Increases font size by 1.
  void increaseFontSize() {
    setFontSize(_fontSize + 1);
  }

  /// Decreases font size by 1.
  void decreaseFontSize() {
    setFontSize(_fontSize - 1);
  }

  /// Sets the font family.
  void setFont(ReaderFont font) {
    _font = font;
    notifyListeners();
  }

  /// Sets an error message.
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clears the current reading session.
  void clearReader() {
    _currentBook = null;
    _chapters = [];
    _currentLocation = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
