import 'package:ereader/notifiers/reader_notifier.dart';
import 'package:ereader/utils/epub_style_injector.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

/// JS interop bridge to encapsulate all WebView JavaScript evaluations.
class EpubJsBridge {
  const EpubJsBridge(this.epubController);

  final EpubController epubController;

  /// Retrieves the current page content location href from the rendition.
  Future<String?> resolveCurrentLocationHref() async {
    final controller = epubController.webViewController;
    if (controller == null) return null;

    final result = await controller.evaluateJavascript(
      source: '''
(function() {
  try {
    var loc = window.rendition.currentLocation();
    return loc && loc.start ? loc.start.href : null;
  } catch(e) {
    return null;
  }
})()
''',
    );

    if (result == null || result == 'null') return null;
    return result.toString();
  }

  /// Injects all reader styling formatting (font size, font family,
  /// line spacing, text alignment, and theme) into the WebView context.
  Future<void> applyFormatting({
    required double fontSize,
    required ReaderFont font,
    required LineSpacing lineSpacing,
    required TextAlignment textAlignment,
    required ReaderTheme theme,
  }) async {
    // 1. Core library font size
    epubController.setFontSize(fontSize: fontSize);

    final controller = epubController.webViewController;
    if (controller == null) return;

    // 2. Custom font-family override
    if (font != ReaderFont.bookDefault) {
      await controller.evaluateJavascript(
        source: 'rendition.themes.font("${font.fontFamily}")',
      );
    }

    // 3. Custom text alignment, line heights, and background/foreground colors
    final styleScript = EpubStyleInjector.buildStyleScript(
      lineHeight: lineSpacing.value,
      textAlign: textAlignment.cssValue,
      bgColor: theme.backgroundCssHex,
      textColor: theme.textCssHex,
    );
    await controller.evaluateJavascript(source: styleScript);

    // 4. Inject bottom padding for page footer progress readability
    await controller.evaluateJavascript(
      source: EpubStyleInjector.bottomPaddingScript,
    );
  }
}
