import 'dart:async';

import 'package:suvadi/notifiers/library_notifier.dart';
import 'package:suvadi/notifiers/reader_notifier.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ReaderNotifier>(
      builder: (context, reader, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Appearance Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Theme Section (Visual Page Cards)
              Text(
                'Color Palette',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ReaderTheme.values.map((t) {
                  final isSelected = reader.theme == t;
                  final bgColor = t.backgroundColor;
                  final textColor = t.textColor;

                  return GestureDetector(
                    onTap: () {
                      reader.setTheme(t);
                      onSettingsChanged();
                    },
                    child: Column(
                      children: [
                        // Page representation card
                        Container(
                          width: 80,
                          height: 56,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Mock line indicators inside mini card
                              Container(
                                width: 44,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: textColor.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                margin: const EdgeInsets.only(bottom: 4),
                              ),
                              Container(
                                width: 38,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: textColor.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                margin: const EdgeInsets.only(bottom: 4),
                              ),
                              Container(
                                width: 42,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: textColor.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Font Family Section
              Text(
                'Typeface',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ReaderFont>(
                  segments: ReaderFont.values.map((f) {
                    return ButtonSegment<ReaderFont>(
                      value: f,
                      label: Text(
                        f.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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

              const SizedBox(height: 24),

              // Font Size Section (Interactive Slider)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Font Size',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${reader.fontSize.toInt()} px',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Text decrease icon indicator
                  Icon(
                    Icons.format_size_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Slider(
                      value: reader.fontSize.clamp(12, 28),
                      min: 12,
                      max: 28,
                      divisions: 8,
                      onChanged: (value) {
                        reader.setFontSize(value);
                        onSettingsChanged();
                        _saveFormatting(context);
                      },
                    ),
                  ),
                  // Text increase icon indicator
                  Icon(
                    Icons.format_size_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Layout Settings Details (Spacing & Alignment Side-by-Side
              // or Stacked)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line Spacing
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spacing',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                            onSelectionChanged: (selected) {
                              reader.setLineSpacing(selected.first);
                              onSettingsChanged();
                              _saveFormatting(context);
                            },
                            showSelectedIcon: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Alignment
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alignment',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<TextAlignment>(
                      segments: const [
                        ButtonSegment<TextAlignment>(
                          value: TextAlignment.left,
                          icon: Icon(Icons.format_align_left_rounded, size: 20),
                        ),
                        ButtonSegment<TextAlignment>(
                          value: TextAlignment.justify,
                          icon: Icon(
                            Icons.format_align_justify_rounded,
                            size: 20,
                          ),
                        ),
                        ButtonSegment<TextAlignment>(
                          value: TextAlignment.center,
                          icon: Icon(
                            Icons.format_align_center_rounded,
                            size: 20,
                          ),
                        ),
                        ButtonSegment<TextAlignment>(
                          value: TextAlignment.right,
                          icon: Icon(
                            Icons.format_align_right_rounded,
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
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
