import 'package:ereader/models/book.dart';
import 'package:ereader/models/reader_enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

export 'package:ereader/models/reader_enums.dart';

/// Manages the EPUB reader state.
class ReaderNotifier extends ChangeNotifier {
  Book? _currentBook;
  List<EpubChapter> _chapters = [];
  EpubLocation? _currentLocation;
  bool _isLoading = false;
  double _fontSize = 16;
  ReaderFont _font = ReaderFont.bookDefault;
  LineSpacing _lineSpacing = LineSpacing.normal;
  TextAlignment _textAlignment = TextAlignment.justify;
  ReaderTheme _theme = ReaderTheme.white;
  String? _error;
  double? _seekTargetProgress;

  Book? get currentBook => _currentBook;
  List<EpubChapter> get chapters => _chapters;
  EpubLocation? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  double get fontSize => _fontSize;
  ReaderFont get font => _font;
  LineSpacing get lineSpacing => _lineSpacing;
  TextAlignment get textAlignment => _textAlignment;
  ReaderTheme get theme => _theme;
  String? get error => _error;
  double? get seekTargetProgress => _seekTargetProgress;

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
    // Clear seek target when we receive a location update close to the target
    if (_seekTargetProgress != null) {
      final diff = (location.progress - _seekTargetProgress!).abs();
      if (diff < 0.02) {
        // Within 2% tolerance
        _seekTargetProgress = null;
      }
    }
    notifyListeners();
  }

  /// Sets the seek target progress (used during slider seek).
  void setSeekTargetProgress(double? progress) {
    _seekTargetProgress = progress;
    notifyListeners();
  }

  /// Sets loading state.
  void setLoading({required bool loading}) {
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

  /// Sets the reader theme.
  void setTheme(ReaderTheme theme) {
    _theme = theme;
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
    _seekTargetProgress = null;
    notifyListeners();
  }
}
