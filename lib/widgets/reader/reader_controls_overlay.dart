import 'package:ereader/models/book.dart';
import 'package:ereader/widgets/reader/reader_bottom_bar.dart';
import 'package:ereader/widgets/reader/reader_top_bar.dart';
import 'package:flutter/material.dart';

/// Overlay that slides in top/bottom frosted glass bars.
class ReaderControlsOverlay extends StatelessWidget {
  const ReaderControlsOverlay({
    required this.book,
    required this.isVisible,
    required this.isLocationLoaded,
    required this.onToggleControls,
    required this.onChaptersTap,
    required this.onSettingsTap,
    required this.onSeek,
    super.key,
  });

  final Book book;
  final bool isVisible;
  final bool isLocationLoaded;
  final VoidCallback onToggleControls;
  final VoidCallback onChaptersTap;
  final VoidCallback onSettingsTap;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dismiss area (always present when visible)
        if (isVisible)
          Positioned.fill(
            child: GestureDetector(
              onTap: onToggleControls,
              behavior: HitTestBehavior.translucent,
              child: const ColoredBox(
                color: Colors.transparent,
              ),
            ),
          ),

        // Top bar — slides down from top
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          top: isVisible ? 0 : -150,
          left: 0,
          right: 0,
          child: ReaderTopBar(
            book: book,
            onChaptersTap: onChaptersTap,
            onSettingsTap: onSettingsTap,
          ),
        ),

        // Bottom bar — slides up from bottom
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          bottom: isVisible ? 0 : -200,
          left: 0,
          right: 0,
          child: ReaderBottomBar(
            book: book,
            isLocationLoaded: isLocationLoaded,
            onSeek: onSeek,
          ),
        ),
      ],
    );
  }
}
