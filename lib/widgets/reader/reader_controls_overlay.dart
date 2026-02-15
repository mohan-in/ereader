import 'package:ereader/models/book.dart';
import 'package:ereader/widgets/reader_bottom_bar.dart';
import 'package:ereader/widgets/reader_top_bar.dart';
import 'package:flutter/material.dart';

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
    if (!isVisible) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onToggleControls,
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
            book: book,
            onChaptersTap: onChaptersTap,
            onSettingsTap: onSettingsTap,
          ),
        ),

        // Bottom bar with seek
        Positioned(
          bottom: 0,
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
