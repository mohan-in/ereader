import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../notifiers/library_notifier.dart';
import '../notifiers/reader_notifier.dart';

class ReaderSettingsSheet extends StatelessWidget {
  final String bookId;
  final VoidCallback onSettingsChanged;

  const ReaderSettingsSheet({
    super.key,
    required this.bookId,
    required this.onSettingsChanged,
  });

  void _saveFormatting(BuildContext context) {
    final reader = context.read<ReaderNotifier>();
    context.read<LibraryNotifier>().updateBookFormatting(
      bookId,
      fontSize: reader.fontSize,
      fontIndex: reader.font.index,
      lineSpacingIndex: reader.lineSpacing.index,
      textAlignmentIndex: reader.textAlignment.index,
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),

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
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  selected: {reader.font},
                  onSelectionChanged: (Set<ReaderFont> selected) {
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
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  selected: {reader.lineSpacing},
                  onSelectionChanged: (Set<LineSpacing> selected) {
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
                      icon: Icon(Icons.format_align_left, size: 20),
                    ),
                    ButtonSegment<TextAlignment>(
                      value: TextAlignment.justify,
                      icon: Icon(Icons.format_align_justify, size: 20),
                    ),
                    ButtonSegment<TextAlignment>(
                      value: TextAlignment.center,
                      icon: Icon(Icons.format_align_center, size: 20),
                    ),
                    ButtonSegment<TextAlignment>(
                      value: TextAlignment.right,
                      icon: Icon(Icons.format_align_right, size: 20),
                    ),
                  ],
                  selected: {reader.textAlignment},
                  onSelectionChanged: (Set<TextAlignment> selected) {
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
