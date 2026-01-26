/// Available fonts for the reader.
enum ReaderFont {
  bookDefault('Book Default', 'inherit'),
  serif('Serif', 'serif'),
  sansSerif('Sans Serif', 'sans-serif');

  const ReaderFont(this.displayName, this.fontFamily);

  final String displayName;
  final String fontFamily;
}

/// Line spacing options for the reader.
enum LineSpacing {
  compact('Compact', 1.2),
  normal('Normal', 1.5),
  relaxed('Relaxed', 1.8),
  loose('Loose', 2.0);

  const LineSpacing(this.displayName, this.value);

  final String displayName;
  final double value;
}

/// Text alignment options for the reader.
enum TextAlignment {
  left('Left', 'left'),
  justify('Justify', 'justify'),
  center('Center', 'center'),
  right('Right', 'right');

  const TextAlignment(this.displayName, this.cssValue);

  final String displayName;
  final String cssValue;
}

/// Reader theme options (background and text colors).
enum ReaderTheme {
  white('White', '#FFFFFF', '#000000'),
  sepia('Sepia', '#F4ECD8', '#5B4636'),
  dark('Dark', '#1A1A1A', '#E0E0E0');

  const ReaderTheme(this.displayName, this.backgroundColor, this.textColor);

  final String displayName;
  final String backgroundColor;
  final String textColor;
}
