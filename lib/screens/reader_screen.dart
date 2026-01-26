import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../notifiers/library_notifier.dart';
import '../notifiers/reader_notifier.dart';
import '../utils/epub_style_injector.dart';
import '../widgets/chapters_sheet.dart';
import '../widgets/reader_bottom_bar.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/reader_top_bar.dart';
import '../widgets/text_selection_sheet.dart';

/// EPUB reader screen with clean gesture handling.
///
/// Navigation:
/// - Tap left edge (25%) to go to previous page
/// - Tap right edge (25%) to go to next page
/// - Tap center of screen to show/hide controls
class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // Constants
  static const double _tapEdgeThreshold = 0.25;
  static const Duration _navigationDelay = Duration(milliseconds: 500);
  static const Duration _postNavigationDelay = Duration(milliseconds: 200);
  static const double _swipeThreshold = 10.0;

  late final EpubController _epubController;
  bool _showControls = false;
  bool _isLocationLoaded = false;

  // Track pointer movement to distinguish taps from swipes
  double _pointerStartX = 0.0;
  double _pointerStartY = 0.0;
  bool _isSwipeGesture = false;

  // Selection state
  final ValueNotifier<EpubTextSelection?> _selectionNotifier = ValueNotifier(
    null,
  );
  bool _isSelectionMenuOpen = false;

  // Flag to skip saving during initial CFI navigation
  bool _isInitialNavigation = true;

  // Saved CFI to restore after epub loads (also used as loading indicator)
  String? _savedCfiToRestore;

  @override
  void initState() {
    super.initState();
    _epubController = EpubController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReaderNotifier>().setCurrentBook(widget.book);
      // Get fresh book data and store CFI to restore
      final freshBook = context.read<LibraryNotifier>().getBook(widget.book.id);
      setState(() {
        _savedCfiToRestore = freshBook?.lastReadCfi ?? widget.book.lastReadCfi;
      });
    });
  }

  @override
  void dispose() {
    _selectionNotifier.dispose();
    super.dispose();
  }

  /// Applies all formatting settings to the epub viewer.
  void _applyFormattingSettings() {
    final reader = context.read<ReaderNotifier>();

    // Apply font size
    _epubController.setFontSize(fontSize: reader.fontSize);

    // Apply font family
    if (reader.font != ReaderFont.bookDefault) {
      _epubController.webViewController?.evaluateJavascript(
        source: 'rendition.themes.font("${reader.font.fontFamily}")',
      );
    }

    // Apply line spacing, text alignment, and theme colors
    final styleScript = EpubStyleInjector.buildStyleScript(
      lineHeight: reader.lineSpacing.value,
      textAlign: reader.textAlignment.cssValue,
      bgColor: reader.theme.backgroundColor,
      textColor: reader.theme.textColor,
    );

    _epubController.webViewController?.evaluateJavascript(source: styleScript);

    // Add padding to bottom to make room for progress footer
    _epubController.webViewController?.evaluateJavascript(
      source: EpubStyleInjector.bottomPaddingScript,
    );

    // Trigger rebuild to update scaffold background
    setState(() {});
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _handleTouch(double normalizedX, double normalizedY) {
    // normalizedX is 0.0 to 1.0 across the screen width
    if (normalizedX < _tapEdgeThreshold) {
      _epubController.prev();
    } else if (normalizedX > (1.0 - _tapEdgeThreshold)) {
      _epubController.next();
    } else {
      _toggleControls();
    }
  }

  void _seekTo(double progress) {
    if (_isLocationLoaded) {
      _epubController.toProgressPercentage(progress.clamp(0.0, 1.0));
    }
  }

  /// Handles keyboard input for DeX/desktop navigation.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final reader = context.read<ReaderNotifier>();

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.pageUp:
        _epubController.prev();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.pageDown:
      case LogicalKeyboardKey.space:
        _epubController.next();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        Navigator.pop(context);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.equal: // + key
      case LogicalKeyboardKey.add:
        reader.increaseFontSize();
        _applyFormattingSettings();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.minus:
        reader.decreaseFontSize();
        _applyFormattingSettings();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderNotifier>();
    final themeBackground = Color(
      int.parse(reader.theme.backgroundColor.replaceFirst('#', '0xFF')),
    );
    final themeTextColor = Color(
      int.parse(reader.theme.textColor.replaceFirst('#', '0xFF')),
    );

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: themeBackground,
        body: SafeArea(
          child: Stack(
            children: [
              // EPUB Viewer - tap left/right edges for page navigation
              Positioned.fill(
                child: Listener(
                  onPointerDown: (e) {
                    _pointerStartX = e.position.dx;
                    _pointerStartY = e.position.dy;
                    _isSwipeGesture = false;
                  },
                  onPointerMove: (e) {
                    if (!_isSwipeGesture) {
                      final dx = (e.position.dx - _pointerStartX).abs();
                      final dy = (e.position.dy - _pointerStartY).abs();
                      if (dx > _swipeThreshold || dy > _swipeThreshold) {
                        _isSwipeGesture = true;
                      }
                    }
                  },
                  // Handle mouse clicks for DeX - onTouchUp only fires for touch
                  onPointerUp: (e) {
                    if (e.kind == PointerDeviceKind.mouse && !_isSwipeGesture) {
                      final size = MediaQuery.of(context).size;
                      final normalizedX = e.position.dx / size.width;
                      final normalizedY = e.position.dy / size.height;
                      _handleTouch(normalizedX, normalizedY);
                    }
                  },
                  child: EpubViewer(
                    epubSource: EpubSource.fromFile(File(widget.book.filePath)),
                    epubController: _epubController,
                    // Note: initialCfi not reliable, we navigate manually in onEpubLoaded
                    displaySettings: EpubDisplaySettings(
                      flow: EpubFlow.paginated,
                      snap: true,
                      allowScriptedContent: true,
                    ),
                    onChaptersLoaded: (chapters) {
                      if (!mounted) return;
                      context.read<ReaderNotifier>().setChapters(chapters);
                    },
                    onLocationLoaded: () {
                      // Progress tracking is now available
                      setState(() {
                        _isLocationLoaded = true;
                      });
                    },
                    onEpubLoaded: () async {
                      if (!mounted) return;
                      context.read<ReaderNotifier>().setLoading(false);

                      // Apply formatting immediately when epub loads
                      _applyFormattingSettings();

                      // Navigate to saved position with a delay to ensure WebView is ready
                      if (_savedCfiToRestore != null &&
                          _savedCfiToRestore!.isNotEmpty) {
                        final cfiToNavigate = _savedCfiToRestore!;
                        _savedCfiToRestore =
                            null; // Clear to prevent re-navigation
                        await Future.delayed(_navigationDelay);
                        if (!mounted) return;
                        _epubController.display(cfi: cfiToNavigate);
                        // Small delay for navigation to complete before hiding overlay
                        await Future.delayed(_postNavigationDelay);
                      }
                      // Hide loading overlay by clearing the CFI
                      if (mounted && _savedCfiToRestore == null) {
                        setState(() {});
                      }

                      try {
                        final metadata = await _epubController.getMetadata();
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        context.read<LibraryNotifier>().updateBookMetadata(
                          widget.book.id,
                          title: metadata.title,
                          author: metadata.author,
                        );
                      } catch (e) {
                        debugPrint('Failed to load metadata: $e');
                      }
                    },
                    onRelocated: (location) {
                      // Only process relocation after initial load is complete
                      // Prevents overwriting persisted progress with 0.0 during initialization
                      if (!mounted || !_isLocationLoaded) return;

                      // Skip the first relocation event to allow initialCfi navigation to complete
                      if (_isInitialNavigation) {
                        _isInitialNavigation = false;
                        return;
                      }

                      context.read<ReaderNotifier>().setCurrentLocation(
                        location,
                      );
                      context.read<LibraryNotifier>().updateReadingProgress(
                        widget.book.id,
                        location.startCfi,
                        progress: location.progress,
                      );
                    },
                    onTextSelected: (selection) {
                      if (selection.selectedText.isNotEmpty) {
                        _selectionNotifier.value = selection;
                        if (!_isSelectionMenuOpen) {
                          _showTextSelectionMenu();
                        }
                      }
                    },
                    onTouchUp: (x, y) {
                      if (_isSwipeGesture) return; // Ignore tap if user swiped
                      _handleTouch(x, y);
                    },
                  ),
                ),
              ),

              // Loading overlay while restoring position
              if (_savedCfiToRestore != null)
                Positioned.fill(
                  child: Container(
                    color: themeBackground,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),

              // Progress Footer
              if ((_isLocationLoaded || widget.book.progress > 0) &&
                  !_showControls)
                Positioned(
                  right: 16,
                  bottom: 8,
                  child: Consumer<ReaderNotifier>(
                    builder: (context, reader, child) {
                      final progress =
                          reader.currentLocation?.progress ??
                          widget.book.progress;
                      return Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeTextColor.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),

              // Controls overlay - only visible when _showControls is true
              if (_showControls) ...[
                // Dismiss overlay when tapping outside controls
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleControls,
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // Top bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ReaderTopBar(
                    book: widget.book,
                    onChaptersTap: () {
                      _toggleControls();
                      _showChaptersSheet();
                    },
                    onSettingsTap: () {
                      _toggleControls();
                      _showFontSettings();
                    },
                  ),
                ),

                // Bottom bar with seek
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ReaderBottomBar(
                    book: widget.book,
                    isLocationLoaded: _isLocationLoaded,
                    onSeek: _seekTo,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showChaptersSheet() {
    _showSheet(
      ChaptersSheet(
        onChapterSelected: (href) {
          Navigator.pop(context);
          _epubController.display(cfi: href);
        },
      ),
    );
  }

  void _showFontSettings() {
    _showSheet(
      ReaderSettingsSheet(
        bookId: widget.book.id,
        onSettingsChanged: _applyFormattingSettings,
      ),
    );
  }

  void _showSheet(Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => child,
    );
  }

  void _showTextSelectionMenu() {
    final selection = _selectionNotifier.value;
    if (selection == null) return;

    _isSelectionMenuOpen = true;
    TextSelectionSheet.show(
      context: context,
      selection: selection,
      epubController: _epubController,
      onDismiss: () {
        _isSelectionMenuOpen = false;
        _selectionNotifier.value = null;
      },
    );
  }
}
