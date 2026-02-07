import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../notifiers/reader_notifier.dart';

/// Bottom bar for the reader screen with progress slider.
class ReaderBottomBar extends StatefulWidget {
  final Book book;
  final bool isLocationLoaded;
  final ValueChanged<double> onSeek;

  const ReaderBottomBar({
    super.key,
    required this.book,
    required this.isLocationLoaded,
    required this.onSeek,
  });

  @override
  State<ReaderBottomBar> createState() => _ReaderBottomBarState();
}

class _ReaderBottomBarState extends State<ReaderBottomBar> {
  bool _isDraggingSlider = false;
  double _sliderValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ReaderNotifier>(
      builder: (context, reader, child) {
        final progress =
            reader.currentLocation?.progress ?? widget.book.progress;
        // Use the seek target if we're seeking, otherwise use actual progress
        final displayValue = _isDraggingSlider
            ? _sliderValue
            : (reader.seekTargetProgress ?? progress).clamp(0.0, 1.0);

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
                          onChangeStart: widget.isLocationLoaded
                              ? (value) {
                                  setState(() {
                                    _isDraggingSlider = true;
                                    _sliderValue = value;
                                  });
                                }
                              : null,
                          onChanged: widget.isLocationLoaded
                              ? (value) {
                                  setState(() {
                                    _sliderValue = value;
                                  });
                                }
                              : null,
                          onChangeEnd: widget.isLocationLoaded
                              ? (value) {
                                  // Set seek target in notifier to hold slider position
                                  // This must happen BEFORE clearing _isDraggingSlider
                                  context
                                      .read<ReaderNotifier>()
                                      .setSeekTargetProgress(value);
                                  setState(() {
                                    _isDraggingSlider = false;
                                  });
                                  // Fire and forget - coordination happens via seekTargetProgress
                                  widget.onSeek(value);
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
}
