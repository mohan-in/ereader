import 'package:flutter/material.dart';

/// Available fonts for the reader.
enum ReaderFont {
  bookDefault('Book Default', 'inherit'),
  serif('Serif', 'serif'),
  sansSerif('Sans Serif', 'sans-serif')
  ;

  const ReaderFont(this.displayName, this.fontFamily);

  final String displayName;
  final String fontFamily;
}

/// Line spacing options for the reader.
enum LineSpacing {
  compact('Compact', 1.2),
  normal('Normal', 1.5),
  relaxed('Relaxed', 1.8),
  loose('Loose', 2)
  ;

  const LineSpacing(this.displayName, this.value);

  final String displayName;
  final double value;
}

/// Text alignment options for the reader.
enum TextAlignment {
  left('Left', 'left'),
  justify('Justify', 'justify'),
  center('Center', 'center'),
  right('Right', 'right')
  ;

  const TextAlignment(this.displayName, this.cssValue);

  final String displayName;
  final String cssValue;
}

/// Reader theme options (background and text colors).
///
/// Stores native [Color] objects for use in Flutter widgets, and
/// exposes CSS hex getters for JavaScript injection into the WebView.
enum ReaderTheme {
  white('White', Color(0xFFFFFFFF), Color(0xFF000000)),
  sepia('Sepia', Color(0xFFF4ECD8), Color(0xFF5B4636)),
  dark('Dark', Color(0xFF1A1A1A), Color(0xFFE0E0E0))
  ;

  const ReaderTheme(this.displayName, this.backgroundColor, this.textColor);

  final String displayName;
  final Color backgroundColor;
  final Color textColor;

  /// CSS hex string for [backgroundColor] (e.g. `#FFFFFF`).
  String get backgroundCssHex => _toCssHex(backgroundColor);

  /// CSS hex string for [textColor] (e.g. `#000000`).
  String get textCssHex => _toCssHex(textColor);

  static String _toCssHex(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }
}
