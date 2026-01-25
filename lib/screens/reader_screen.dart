import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../notifiers/library_notifier.dart';
import '../notifiers/reader_notifier.dart';
import '../widgets/chapters_sheet.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/text_selection_sheet.dart';

/// EPUB reader screen with clean gesture handling.
///
/// Navigation:
/// - Swipe left/right on content to turn pages (handled by epub.js)
/// - Tap center of screen to show/hide controls
/// - Tap left/right edges to turn pages
class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final EpubController _epubController;
  bool _showControls = false;
  bool _isLocationLoaded = false;

  // Slider state for smooth dragging
  bool _isDraggingSlider = false;
  double _sliderValue = 0.0;

  // Swipe detection
  double _swipeStartX = 0.0;
  double _swipeStartY = 0.0;
  bool _justSwiped = false;

  // Selection state
  final ValueNotifier<EpubTextSelection?> _selectionNotifier = ValueNotifier(
    null,
  );
  bool _isSelectionMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _epubController = EpubController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReaderNotifier>().setCurrentBook(widget.book);
    });
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

    // Apply line spacing and text alignment using override
    final lineHeight = reader.lineSpacing.value;
    final textAlign = reader.textAlignment.cssValue;

    _epubController.webViewController?.evaluateJavascript(
      source: 'rendition.themes.override("line-height", "$lineHeight", true)',
    );
    _epubController.webViewController?.evaluateJavascript(
      source: 'rendition.themes.override("text-align", "$textAlign", true)',
    );

    // Add padding to bottom to make room for progress footer
    _epubController.webViewController?.evaluateJavascript(
      source: 'rendition.themes.override("padding-bottom", "30px", true)',
    );
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _handleTouch(double normalizedX, double normalizedY) {
    // normalizedX is 0.0 to 1.0 across the screen width
    if (normalizedX < 0.25) {
      _epubController.prev();
    } else if (normalizedX > 0.75) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // EPUB Viewer - takes full screen, handles its own gestures
            Positioned.fill(
              child: Listener(
                onPointerDown: (e) {
                  _swipeStartX = e.position.dx;
                  _swipeStartY = e.position.dy;
                },
                onPointerUp: (e) {
                  final deltaX = e.position.dx - _swipeStartX;
                  final deltaY = e.position.dy - _swipeStartY;
                  // Horizontal swipe (significant X movement, minimal Y movement)
                  if (deltaX.abs() > 50 && deltaY.abs() < 50) {
                    _justSwiped = true;
                    // Reset flag after a short delay to allow JS event to fire and be ignored
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) _justSwiped = false;
                    });

                    if (deltaX > 0) {
                      _epubController.prev();
                    } else {
                      _epubController.next();
                    }
                  }
                },
                child: EpubViewer(
                  epubSource: EpubSource.fromFile(File(widget.book.filePath)),
                  epubController: _epubController,
                  initialCfi: widget.book.lastReadCfi,
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
                    // Apply saved formatting settings after location is ready
                    _applyFormattingSettings();
                  },
                  onEpubLoaded: () async {
                    if (!mounted) return;
                    context.read<ReaderNotifier>().setLoading(false);

                    // Apply formatting immediately when epub loads
                    _applyFormattingSettings();

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

                    context.read<ReaderNotifier>().setCurrentLocation(location);
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
                  // Touch callback for tap zones
                  onTouchUp: (x, y) {
                    if (_justSwiped) return;
                    _handleTouch(x, y);
                  },
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
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
              Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

              // Bottom bar with seek
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<ReaderNotifier>(
      builder: (context, reader, child) {
        return Material(
          color: colorScheme.surface,
          elevation: 4,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Title
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reader.currentBook?.title ?? widget.book.title,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        if (reader.currentBook?.author != null)
                          Text(
                            reader.currentBook!.author!,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),

                  // Chapters button
                  IconButton(
                    icon: Icon(
                      Icons.toc_outlined,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: () {
                      _toggleControls();
                      _showChaptersSheet();
                    },
                    tooltip: 'Chapters',
                  ),

                  // Font size button
                  IconButton(
                    icon: Icon(
                      Icons.format_size_outlined,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: () {
                      _toggleControls();
                      _showFontSettings();
                    },
                    tooltip: 'Appearance',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<ReaderNotifier>(
      builder: (context, reader, child) {
        final progress =
            reader.currentLocation?.progress ?? widget.book.progress;
        final displayValue = _isDraggingSlider
            ? _sliderValue
            : progress.clamp(0.0, 1.0);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Progress Text
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(displayValue * 100).toInt()}%',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Slider
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor:
                              colorScheme.surfaceContainerHighest,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 20,
                          ),
                        ),
                        child: Slider(
                          value: displayValue,
                          onChangeStart: _isLocationLoaded
                              ? (value) {
                                  setState(() {
                                    _isDraggingSlider = true;
                                    _sliderValue = value;
                                  });
                                }
                              : null,
                          onChanged: _isLocationLoaded
                              ? (value) {
                                  setState(() {
                                    _sliderValue = value;
                                  });
                                }
                              : null,
                          onChangeEnd: _isLocationLoaded
                              ? (value) {
                                  _seekTo(value);
                                  setState(() {
                                    _isDraggingSlider = false;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChaptersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ChaptersSheet(
        onChapterSelected: (href) {
          Navigator.pop(context);
          _epubController.display(cfi: href);
        },
      ),
    );
  }

  void _showFontSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReaderSettingsSheet(
        bookId: widget.book.id,
        onSettingsChanged: _applyFormattingSettings,
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
