import 'dart:async';

import 'package:ereader/notifiers/library_notifier.dart';
import 'package:ereader/notifiers/reader_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({
    required this.bookId,
    required this.onSettingsChanged,
    super.key,
  });

  final String bookId;
  final VoidCallback onSettingsChanged;

  void _saveFormatting(BuildContext context) {
    final reader = context.read<ReaderNotifier>();
    unawaited(
      context.read<LibraryNotifier>().updateBookFormatting(
        bookId,
        fontSize: reader.fontSize,
        fontIndex: reader.font.index,
        lineSpacingIndex: reader.lineSpacing.index,
        textAlignmentIndex: reader.textAlignment.index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderNotifier>(
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
                  margin: const EdgeInsets.only(
                    bottom: 24,
                  ),
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

              // Theme Section
              Text(
                'Theme',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ReaderTheme.values.map((theme) {
                  final isSelected = reader.theme == theme;
                  final bgColor = Color(
                    int.parse(
                      theme.backgroundColor.replaceFirst('#', '0xFF'),
                    ),
                  );
                  final textColor = Color(
                    int.parse(
                      theme.textColor.replaceFirst(
                        '#',
                        '0xFF',
                      ),
                    ),
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        reader.setTheme(theme);
                        onSettingsChanged();
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Aa',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            theme.displayName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Font Family Section
              Text(
                'Font',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ReaderFont>(
                  segments: ReaderFont.values.map((font) {
                    return ButtonSegment<ReaderFont>(
                      value: font,
                      label: Text(
                        font.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                  selected: {reader.font},
                  onSelectionChanged: (selected) {
                    reader.setFont(selected.first);
                    onSettingsChanged();
                    _saveFormatting(context);
                  },
                  showSelectedIcon: false,
                ),
              ),

              const SizedBox(height: 20),

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
                      onSettingsChanged();
                      _saveFormatting(context);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                    ),
                    child: Text(
                      '${reader.fontSize.toInt()}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      reader.increaseFontSize();
                      onSettingsChanged();
                      _saveFormatting(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Line Spacing Section
              Text(
                'Line Spacing',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<LineSpacing>(
                  segments: LineSpacing.values.map((spacing) {
                    return ButtonSegment<LineSpacing>(
                      value: spacing,
                      label: Text(
                        spacing.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                  selected: {reader.lineSpacing},
                  onSelectionChanged: (selected) {
                    reader.setLineSpacing(selected.first);
                    onSettingsChanged();
                    _saveFormatting(context);
                  },
                  showSelectedIcon: false,
                ),
              ),

              const SizedBox(height: 20),

              // Text Alignment Section
              Text(
                'Text Alignment',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<TextAlignment>(
                  segments: const [
                    ButtonSegment<TextAlignment>(
                      value: TextAlignment.left,
                      icon: Icon(
                        Icons.format_align_left,
                        size: 20,
                      ),
                    ),
                    ButtonSegment<TextAlignment>(
                      value: TextAlignment.justify,
                      icon: Icon(
                        Icons.format_align_justify,
                        size: 20,
                      ),
                    ),
                    ButtonSegment<TextAlignment>(
                      value: TextAlignment.center,
                      icon: Icon(
                        Icons.format_align_center,
                        size: 20,
                      ),
                    ),
                    ButtonSegment<TextAlignment>(
                      value: TextAlignment.right,
                      icon: Icon(
                        Icons.format_align_right,
                        size: 20,
                      ),
                    ),
                  ],
                  selected: {reader.textAlignment},
                  onSelectionChanged: (selected) {
                    reader.setTextAlignment(selected.first);
                    onSettingsChanged();
                    _saveFormatting(context);
                  },
                  showSelectedIcon: false,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
