/// Helper class for injecting CSS styles into the EPUB viewer.
///
/// Encapsulates JavaScript generation for cleaner code in the reader screen.
class EpubStyleInjector {
  EpubStyleInjector._();

  /// Builds the JavaScript to apply reader styling to EPUB content.
  ///
  /// Registers a hook for future page loads and applies styles immediately
  /// to the current page content.
  static String buildStyleScript({
    required double lineHeight,
    required String textAlign,
    required String bgColor,
    required String textColor,
  }) {
    return '''
(function() {
  // Register hook for future page loads (re-register overwrites previous)
  if (typeof rendition !== 'undefined' && rendition.hooks) {
    rendition.hooks.content.register(function(contents) {
      contents.addStylesheetRules([
        ['*', ['line-height', '$lineHeight', true]],
        ['*', ['color', '$textColor', true]],
        ['body', ['background-color', '$bgColor', true]],
        ['p, div, span, li, td, th, blockquote, pre', ['line-height', '$lineHeight', true]],
        ['p, div, span, li, td, th, blockquote, pre', ['text-align', '$textAlign', true]],
        ['a', ['color', '$textColor', true]]
      ]);
    });
  }
  
  // Apply immediately to current page
  if (typeof rendition !== 'undefined' && rendition.getContents) {
    rendition.getContents().forEach(function(contents) {
      contents.addStylesheetRules([
        ['*', ['line-height', '$lineHeight', true]],
        ['*', ['color', '$textColor', true]],
        ['body', ['background-color', '$bgColor', true]],
        ['p, div, span, li, td, th, blockquote, pre', ['line-height', '$lineHeight', true]],
        ['p, div, span, li, td, th, blockquote, pre', ['text-align', '$textAlign', true]],
        ['a', ['color', '$textColor', true]]
      ]);
    });
  }
})()
''';
  }

  /// JavaScript to add bottom padding for progress footer.
  static String get bottomPaddingScript =>
      'rendition.themes.override("padding-bottom", "30px", true)';
}
