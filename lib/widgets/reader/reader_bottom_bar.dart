import 'dart:ui';

import 'package:suvadi/models/book.dart';
import 'package:suvadi/notifiers/reader_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Bottom bar for the reader screen with frosted glass effect,
/// chapter name, and progress slider.
class ReaderBottomBar extends StatefulWidget {
  const ReaderBottomBar({
    required this.book,
    required this.isLocationLoaded,
    required this.onSeek,
    super.key,
  });

  final Book book;
  final bool isLocationLoaded;
  final ValueChanged<double> onSeek;

  @override
  State<ReaderBottomBar> createState() => _ReaderBottomBarState();
}

class _ReaderBottomBarState extends State<ReaderBottomBar> {
  bool _isDraggingSlider = false;
  double _sliderValue = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderNotifier>(
      builder: (context, reader, child) {
        final progress =
            reader.currentLocation?.progress ?? widget.book.progress;
        final displayValue = _isDraggingSlider
            ? _sliderValue
            : (reader.seekTargetProgress ?? progress).clamp(0.0, 1.0);
        final chapterTitle = reader.currentChapterTitle;

        final readerTheme = reader.theme;
        final bgColor = readerTheme.backgroundColor;
        final textColor = readerTheme.textColor;

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.85),
                border: Border(
                  top: BorderSide(
                    color: textColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Chapter Title & Progress Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chapterTitle ?? 'Reading...',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(displayValue * 100).toInt()}%',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Slider Row
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          activeTrackColor: textColor,
                          inactiveTrackColor: textColor.withValues(alpha: 0.2),
                          thumbColor: textColor,
                          overlayColor: textColor.withValues(alpha: 0.1),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 18,
                          ),
                        ),
                        child: SizedBox(
                          height: 32,
                          child: Slider(
                            value: displayValue,
                            onChangeStart: (value) {
                              setState(() {
                                _isDraggingSlider = true;
                                _sliderValue = value;
                              });
                            },
                            onChanged: (value) {
                              setState(() {
                                _sliderValue = value;
                              });
                            },
                            onChangeEnd: (value) {
                              context
                                  .read<ReaderNotifier>()
                                  .setSeekTargetProgress(value);
                              setState(() {
                                _isDraggingSlider = false;
                              });
                              widget.onSeek(value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
