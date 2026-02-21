import 'dart:async';

import 'package:ereader/widgets/sheet_drag_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

/// Bottom sheet for text selection actions (highlight, copy).
///
/// Displays the selected text preview and action buttons.
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SheetDragHandle(),

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
              style: const TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(
                    Icons.highlight,
                    color: Colors.orange,
                  ),
                  label: const Text('Highlight'),
                  onPressed: onHighlight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
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
