import 'package:flutter/foundation.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../models/book.dart';

/// Available fonts for the reader.
enum ReaderFont {
  bookDefault('Book Default', 'inherit'),
  serif('Serif', 'serif'),
  sansSerif('Sans Serif', 'sans-serif');

  final String displayName;
  final String fontFamily;

  const ReaderFont(this.displayName, this.fontFamily);
}

/// Line spacing options for the reader.
enum LineSpacing {
  compact('Compact', 1.2),
  normal('Normal', 1.5),
  relaxed('Relaxed', 1.8),
  loose('Loose', 2.0);

  final String displayName;
  final double value;

  const LineSpacing(this.displayName, this.value);
}

/// Text alignment options for the reader.
enum TextAlignment {
  left('Left', 'left'),
  justify('Justify', 'justify'),
  center('Center', 'center'),
  right('Right', 'right');

  final String displayName;
  final String cssValue;

  const TextAlignment(this.displayName, this.cssValue);
}

/// Manages the EPUB reader state.
class ReaderNotifier extends ChangeNotifier {
  Book? _currentBook;
  List<EpubChapter> _chapters = [];
  EpubLocation? _currentLocation;
  bool _isLoading = false;
  double _fontSize = 16.0;
  ReaderFont _font = ReaderFont.bookDefault;
  LineSpacing _lineSpacing = LineSpacing.normal;
  TextAlignment _textAlignment = TextAlignment.justify;
  String? _error;

  Book? get currentBook => _currentBook;
  List<EpubChapter> get chapters => _chapters;
  EpubLocation? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  double get fontSize => _fontSize;
  ReaderFont get font => _font;
  LineSpacing get lineSpacing => _lineSpacing;
  TextAlignment get textAlignment => _textAlignment;
  String? get error => _error;

  /// Sets the current book to read and loads its formatting preferences.
  void setCurrentBook(Book book) {
    _currentBook = book;
    _chapters = [];
    _currentLocation = null;
    _error = null;

    // Load formatting from book
    _fontSize = book.fontSize;
    _font = book.fontIndex < ReaderFont.values.length
        ? ReaderFont.values[book.fontIndex]
        : ReaderFont.bookDefault;
    _lineSpacing = book.lineSpacingIndex < LineSpacing.values.length
        ? LineSpacing.values[book.lineSpacingIndex]
        : LineSpacing.normal;
    _textAlignment = book.textAlignmentIndex < TextAlignment.values.length
        ? TextAlignment.values[book.textAlignmentIndex]
        : TextAlignment.justify;

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

  /// Sets the line spacing.
  void setLineSpacing(LineSpacing spacing) {
    _lineSpacing = spacing;
    notifyListeners();
  }

  /// Sets the text alignment.
  void setTextAlignment(TextAlignment alignment) {
    _textAlignment = alignment;
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
