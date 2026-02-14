import 'dart:async';
import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:ereader/models/book.dart';
import 'package:ereader/notifiers/library_notifier.dart';
import 'package:ereader/notifiers/reader_notifier.dart';
import 'package:ereader/utils/epub_style_injector.dart';
import 'package:ereader/widgets/chapters_sheet.dart';
import 'package:ereader/widgets/reader_bottom_bar.dart';
import 'package:ereader/widgets/reader_settings_sheet.dart';
import 'package:ereader/widgets/reader_top_bar.dart';
import 'package:ereader/widgets/text_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:provider/provider.dart';

/// EPUB reader screen with clean gesture handling.
///
/// Navigation:
/// - Tap left edge (25%) to go to previous page
/// - Tap right edge (25%) to go to next page
/// - Tap center of screen to show/hide controls
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({required this.book, super.key});

  final Book book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // Constants
  static const double _tapEdgeThreshold = 0.25;
  static const Duration _navigationDelay = Duration(milliseconds: 500);
  static const Duration _postNavigationDelay = Duration(milliseconds: 200);
  static const double _swipeThreshold = 10;

  late final EpubController _epubController;
  bool _showControls = false;
  bool _isLocationLoaded = false;

  // Track pointer movement to distinguish taps from swipes
  double _pointerStartX = 0;
  double _pointerStartY = 0;
  bool _isSwipeGesture = false;

  // Selection state
  final ValueNotifier<EpubTextSelection?> _selectionNotifier = ValueNotifier(
    null,
  );
  bool _isSelectionMenuOpen = false;

  // Flag to skip saving during initial CFI navigation
  bool _isInitialNavigation = true;

  // Saved CFI to restore after epub loads
  String? _savedCfiToRestore;

  // Flag to show loading overlay while restoring position
  bool _isRestoringPosition = false;

  @override
  void initState() {
    super.initState();
    _epubController = EpubController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReaderNotifier>().setCurrentBook(widget.book);
      // Get fresh book data and store CFI to restore
      final freshBook = context.read<LibraryNotifier>().getBook(widget.book.id);
      final cfi = freshBook?.lastReadCfi ?? widget.book.lastReadCfi;
      setState(() {
        _savedCfiToRestore = cfi;
        _isRestoringPosition = cfi != null && cfi.isNotEmpty;
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
    _epubController.setFontSize(
      fontSize: reader.fontSize,
    );

    // Apply font family
    if (reader.font != ReaderFont.bookDefault) {
      unawaited(
        _epubController.webViewController?.evaluateJavascript(
              source: 'rendition.themes.font("${reader.font.fontFamily}")',
            ) ??
            Future<void>.value(),
      );
    }

    // Apply line spacing, text alignment, and theme
    final styleScript = EpubStyleInjector.buildStyleScript(
      lineHeight: reader.lineSpacing.value,
      textAlign: reader.textAlignment.cssValue,
      bgColor: reader.theme.backgroundColor,
      textColor: reader.theme.textColor,
    );

    unawaited(
      _epubController.webViewController?.evaluateJavascript(
            source: styleScript,
          ) ??
          Future<void>.value(),
    );

    // Add padding to bottom for progress footer
    unawaited(
      _epubController.webViewController?.evaluateJavascript(
            source: EpubStyleInjector.bottomPaddingScript,
          ) ??
          Future<void>.value(),
    );

    // Trigger rebuild to update scaffold background
    setState(() {});
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _handleTouch(
    double normalizedX,
    double normalizedY,
  ) {
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
      _epubController.toProgressPercentage(
        progress.clamp(0.0, 1.0),
      );
    }
  }

  /// Handles keyboard input for DeX/desktop navigation.
  KeyEventResult _handleKeyEvent(
    FocusNode node,
    KeyEvent event,
  ) {
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
      int.parse(
        reader.theme.backgroundColor.replaceFirst('#', '0xFF'),
      ),
    );
    final themeTextColor = Color(
      int.parse(
        reader.theme.textColor.replaceFirst('#', '0xFF'),
      ),
    );

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: themeBackground,
        body: SafeArea(
          child: Stack(
            children: [
              // EPUB Viewer
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
                  onPointerUp: (e) {
                    if (e.kind == PointerDeviceKind.mouse && !_isSwipeGesture) {
                      final size = MediaQuery.of(context).size;
                      final normalizedX = e.position.dx / size.width;
                      final normalizedY = e.position.dy / size.height;
                      _handleTouch(
                        normalizedX,
                        normalizedY,
                      );
                    }
                  },
                  child: EpubViewer(
                    epubSource: EpubSource.fromFile(
                      File(widget.book.filePath),
                    ),
                    epubController: _epubController,
                    displaySettings: EpubDisplaySettings(),
                    onChaptersLoaded: (chapters) {
                      if (!mounted) return;
                      context.read<ReaderNotifier>().setChapters(chapters);
                    },
                    onLocationLoaded: () {
                      setState(() {
                        _isLocationLoaded = true;
                      });
                    },
                    onEpubLoaded: () async {
                      if (!mounted) return;
                      final libraryNotifier = context.read<LibraryNotifier>();
                      context.read<ReaderNotifier>().setLoading(loading: false);

                      _applyFormattingSettings();

                      if (_savedCfiToRestore != null &&
                          _savedCfiToRestore!.isNotEmpty) {
                        final cfiToNavigate = _savedCfiToRestore!;
                        _savedCfiToRestore = null;
                        await Future<void>.delayed(
                          _navigationDelay,
                        );
                        if (!mounted) return;
                        _epubController.display(
                          cfi: cfiToNavigate,
                        );
                        await Future<void>.delayed(
                          _postNavigationDelay,
                        );
                      }
                      if (mounted) {
                        setState(() {
                          _isRestoringPosition = false;
                        });
                      }

                      try {
                        final metadata = await _epubController.getMetadata();
                        if (!mounted) return;
                        unawaited(
                          libraryNotifier.updateBookMetadata(
                            widget.book.id,
                            title: metadata.title,
                            author: metadata.author,
                          ),
                        );
                      } on Exception catch (e) {
                        debugPrint(
                          'Failed to load metadata: $e',
                        );
                      }
                    },
                    onRelocated: (location) {
                      if (!mounted || !_isLocationLoaded) {
                        return;
                      }

                      if (_isInitialNavigation) {
                        _isInitialNavigation = false;
                        return;
                      }

                      context.read<ReaderNotifier>().setCurrentLocation(
                        location,
                      );
                      unawaited(
                        context.read<LibraryNotifier>().updateReadingProgress(
                          widget.book.id,
                          location.startCfi,
                          progress: location.progress,
                        ),
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
                      if (_isSwipeGesture) return;
                      _handleTouch(x, y);
                    },
                  ),
                ),
              ),

              // Loading overlay while restoring position
              if (_isRestoringPosition)
                Positioned.fill(
                  child: ColoredBox(
                    color: themeBackground,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
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
                          color: themeTextColor.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),

              // Controls overlay
              if (_showControls) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleControls,
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      color: Colors.transparent,
                    ),
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
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        builder: (_) => child,
      ),
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
