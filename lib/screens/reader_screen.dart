import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../notifiers/library_notifier.dart';
import '../notifiers/reader_notifier.dart';

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

  @override
  void initState() {
    super.initState();
    _epubController = EpubController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReaderNotifier>().setCurrentBook(widget.book);
    });
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
                },
                onEpubLoaded: () async {
                  if (!mounted) return;
                  context.read<ReaderNotifier>().setLoading(false);

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
                  if (!mounted) return;
                  context.read<ReaderNotifier>().setCurrentLocation(location);
                  context.read<LibraryNotifier>().updateReadingProgress(
                    widget.book.id,
                    location.startCfi,
                  );
                },
                onTextSelected: (selection) {
                  if (selection.selectedText.isNotEmpty) {
                    _showTextSelectionMenu(selection);
                  }
                },
                // Touch callback for tap zones
                onTouchUp: (x, y) {
                  _handleTouch(x, y);
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
    return Consumer<ReaderNotifier>(
      builder: (context, reader, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.black54, Colors.transparent],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Title
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reader.currentBook?.title ?? widget.book.title,
                          style: const TextStyle(
                            color: Colors.white,
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
                              color: Colors.white70,
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
                    icon: const Icon(Icons.list, color: Colors.white),
                    onPressed: () {
                      _toggleControls();
                      _showChaptersSheet();
                    },
                    tooltip: 'Chapters',
                  ),

                  // Font size button
                  IconButton(
                    icon: const Icon(Icons.text_fields, color: Colors.white),
                    onPressed: () {
                      _toggleControls();
                      _showFontSettings();
                    },
                    tooltip: 'Font Size',
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
    return Consumer<ReaderNotifier>(
      builder: (context, reader, child) {
        final progress = reader.currentLocation?.progress ?? 0.0;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.black54, Colors.transparent],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${((_isDraggingSlider ? _sliderValue : progress) * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isLocationLoaded)
                        Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Seek slider
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20,
                      ),
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Colors.white30,
                      thumbColor: Colors.white,
                      overlayColor: Colors.white24,
                    ),
                    child: Slider(
                      value: _isDraggingSlider
                          ? _sliderValue
                          : progress.clamp(0.0, 1.0),
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

                  const SizedBox(height: 4),

                  // Hint
                  Text(
                    'Swipe or tap edges to turn pages',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChaptersSheet() {
    final reader = context.read<ReaderNotifier>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.list,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Chapters',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Chapter list
              Expanded(
                child: reader.chapters.isEmpty
                    ? const Center(child: Text('No chapters available'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: reader.chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = reader.chapters[index];
                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _epubController.display(cfi: chapter.href);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      chapter.title.isNotEmpty
                                          ? chapter.title
                                          : 'Chapter ${index + 1}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
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
      builder: (context) => Consumer<ReaderNotifier>(
        builder: (context, reader, child) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Center(
                  child: Text(
                    'Reading Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Font Size Section
                Text(
                  'Font Size',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        reader.decreaseFontSize();
                        _epubController.setFontSize(fontSize: reader.fontSize);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '${reader.fontSize.toInt()}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        reader.increaseFontSize();
                        _epubController.setFontSize(fontSize: reader.fontSize);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTextSelectionMenu(EpubTextSelection selection) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Selected text preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${selection.selectedText}"',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.highlight, color: Colors.orange),
                    label: const Text('Highlight'),
                    onPressed: () {
                      Navigator.pop(context);
                      if (selection.selectionCfi.isNotEmpty) {
                        _epubController.addHighlight(
                          cfi: selection.selectionCfi,
                          color: Colors.yellow,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                    onPressed: () {
                      Navigator.pop(context);
                      Clipboard.setData(
                        ClipboardData(text: selection.selectedText),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
