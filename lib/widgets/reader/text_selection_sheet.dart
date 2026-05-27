import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

/// Bottom sheet for text selection actions (highlight, copy).
///
/// Displays the selected text preview and action buttons following M3.
class TextSelectionSheet extends StatelessWidget {
  const TextSelectionSheet({
    required this.selection,
    required this.onHighlight,
    required this.onCopy,
    super.key,
  });

  final EpubTextSelection selection;
  final VoidCallback onHighlight;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Selected text preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '"${selection.selectedText}"',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.highlight_rounded,
                    color: Colors.orange,
                  ),
                  label: const Text('Highlight'),
                  onPressed: onHighlight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.content_copy_rounded),
                  label: const Text('Copy'),
                  onPressed: onCopy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Shows the text selection sheet and handles actions.
  static void show({
    required BuildContext context,
    required EpubTextSelection selection,
    required EpubController epubController,
    required VoidCallback onDismiss,
  }) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent, // Let Container handle background
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        builder: (context) => TextSelectionSheet(
          selection: selection,
          onHighlight: () {
            Navigator.pop(context);
            if (selection.selectionCfi.isNotEmpty) {
              epubController.addHighlight(
                cfi: selection.selectionCfi,
              );
            }
          },
          onCopy: () {
            Navigator.pop(context);
            unawaited(
              Clipboard.setData(
                ClipboardData(
                  text: selection.selectedText,
                ),
              ),
            );
          },
        ),
      ).whenComplete(onDismiss),
    );
  }
}
