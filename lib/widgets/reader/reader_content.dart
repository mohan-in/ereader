import 'dart:io';
import 'dart:ui';

import 'package:ereader/models/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

class ReaderContent extends StatefulWidget {
  const ReaderContent({
    required this.book,
    required this.epubController,
    required this.overlayEntry,
    required this.onTapLeft,
    required this.onTapRight,
    required this.onTapCenter,
    required this.onChaptersLoaded,
    required this.onLocationLoaded,
    required this.onEpubLoaded,
    required this.onRelocated,
    required this.onTextSelected,
    super.key,
  });

  final Book book;
  final EpubController epubController;
  final Widget? overlayEntry;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;
  final VoidCallback onTapCenter;
  final ValueChanged<List<EpubChapter>> onChaptersLoaded;
  final VoidCallback onLocationLoaded;
  final VoidCallback onEpubLoaded;
  final ValueChanged<EpubLocation> onRelocated;
  final ValueChanged<EpubTextSelection> onTextSelected;

  @override
  State<ReaderContent> createState() => _ReaderContentState();
}

class _ReaderContentState extends State<ReaderContent> {
  static const double _tapEdgeThreshold = 0.25;
  static const double _swipeThreshold = 10;

  double _pointerStartX = 0;
  double _pointerStartY = 0;
  bool _isSwipeGesture = false;

  void _handleTouch(double normalizedX, double normalizedY) {
    if (normalizedX < _tapEdgeThreshold) {
      widget.onTapLeft();
    } else if (normalizedX > (1.0 - _tapEdgeThreshold)) {
      widget.onTapRight();
    } else {
      widget.onTapCenter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
                _handleTouch(normalizedX, normalizedY);
              }
            },
            child: EpubViewer(
              epubSource: EpubSource.fromFile(
                File(widget.book.filePath),
              ),
              epubController: widget.epubController,
              displaySettings: EpubDisplaySettings(),
              onChaptersLoaded: widget.onChaptersLoaded,
              onLocationLoaded: widget.onLocationLoaded,
              onEpubLoaded: widget.onEpubLoaded,
              onRelocated: widget.onRelocated,
              onTextSelected: widget.onTextSelected,
              onTouchUp: (x, y) {
                if (_isSwipeGesture) return;
                _handleTouch(x, y);
              },
            ),
          ),
        ),
        if (widget.overlayEntry != null) widget.overlayEntry!,
      ],
    );
  }
}
