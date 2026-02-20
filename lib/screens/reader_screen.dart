import 'dart:async';

import 'package:ereader/models/book.dart';
import 'package:ereader/notifiers/library_notifier.dart';
import 'package:ereader/notifiers/reader_notifier.dart';
import 'package:ereader/utils/epub_style_injector.dart';
import 'package:ereader/widgets/reader/chapters_sheet.dart';
import 'package:ereader/widgets/reader/reader_content.dart';
import 'package:ereader/widgets/reader/reader_controls_overlay.dart';
import 'package:ereader/widgets/reader/reader_footer.dart';
import 'package:ereader/widgets/reader/reader_settings_sheet.dart';
import 'package:ereader/widgets/reader/text_selection_sheet.dart';
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
  static const Duration _navigationDelay = Duration(milliseconds: 500);
  static const Duration _postNavigationDelay = Duration(milliseconds: 200);

  late final EpubController _epubController;
  bool _showControls = false;
  bool _isLocationLoaded = false;

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

  late final LibraryNotifier _libraryNotifier;
  double? _pendingSeekProgress;

  @override
  void initState() {
    super.initState();
    _libraryNotifier = context.read<LibraryNotifier>();
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

  /// Fire-and-forget save of the current location.
  /// Used when the user closes the screen to ensure the latest location is
  /// saved even if `onRelocated` hasn't fired yet.
  void _saveCurrentLocation() {
    try {
      if (_isLocationLoaded && _epubController.webViewController != null) {
        final bookId = widget.book.id;
        unawaited(
          _epubController
              .getCurrentLocation()
              .then((location) {
                unawaited(
                  _libraryNotifier.updateReadingProgress(
                    bookId,
                    location.startCfi,
                    progress: location.progress,
                  ),
                );
              })
              .catchError((_) {}),
        );
      }
    } on Exception catch (_) {
      // Ignore errors during dispose
    }
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

  void _seekTo(double progress) {
    if (_isLocationLoaded) {
      _epubController.toProgressPercentage(
        progress.clamp(0.0, 1.0),
      );
    } else {
      // Save it to be applied when locations finally load
      setState(() {
        _pendingSeekProgress = progress;
        _isRestoringPosition = true;
      });
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
      child: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            _saveCurrentLocation();
          }
        },
        child: Scaffold(
          backgroundColor: themeBackground,
          body: SafeArea(
            child: Stack(
              children: [
                // EPUB Viewer
                ReaderContent(
                  book: widget.book,
                  epubController: _epubController,
                  overlayEntry: _isRestoringPosition
                      ? ColoredBox(
                          color: themeBackground,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : null,
                  onTapLeft: () => _epubController.prev(),
                  onTapRight: () => _epubController.next(),
                  onTapCenter: _toggleControls,
                  onChaptersLoaded: (chapters) {
                    if (!mounted) return;
                    context.read<ReaderNotifier>().setChapters(chapters);
                  },
                  onLocationLoaded: () {
                    if (!mounted) return;
                    setState(() {
                      _isLocationLoaded = true;
                    });
                    if (_pendingSeekProgress != null) {
                      _seekTo(_pendingSeekProgress!);
                      _pendingSeekProgress = null;
                      setState(() {
                        _isRestoringPosition = false;
                      });
                    }
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
                    if (!_isLocationLoaded) {
                      return;
                    }

                    if (_isInitialNavigation) {
                      _isInitialNavigation = false;
                      return;
                    }

                    if (mounted) {
                      context.read<ReaderNotifier>().setCurrentLocation(
                        location,
                      );
                    }

                    // Always try to save the progress to library
                    // even if unmounted, to prevent dropped locations
                    // when the user closes during pagination.
                    unawaited(
                      _libraryNotifier.updateReadingProgress(
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
                ),

                // Progress Footer
                if ((_isLocationLoaded || widget.book.progress > 0) &&
                    !_showControls)
                  ReaderFooter(
                    book: widget.book,
                    themeTextColor: themeTextColor,
                  ),

                // Controls overlay
                ReaderControlsOverlay(
                  book: widget.book,
                  isVisible: _showControls,
                  isLocationLoaded: _isLocationLoaded,
                  onToggleControls: _toggleControls,
                  onChaptersTap: () {
                    _toggleControls();
                    _showChaptersSheet();
                  },
                  onSettingsTap: () {
                    _toggleControls();
                    _showFontSettings();
                  },
                  onSeek: _seekTo,
                ),
              ],
            ),
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
