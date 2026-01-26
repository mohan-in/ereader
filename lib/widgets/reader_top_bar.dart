import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../notifiers/reader_notifier.dart';

/// Callback when a chapter is selected.
typedef ChapterSelectedCallback = void Function(String href);

/// Callback when settings are changed.
typedef SettingsChangedCallback = void Function();

/// Top bar for the reader screen with title, back button, and action buttons.
class ReaderTopBar extends StatelessWidget {
  final Book book;
  final VoidCallback onChaptersTap;
  final VoidCallback onSettingsTap;

  const ReaderTopBar({
    super.key,
    required this.book,
    required this.onChaptersTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ReaderNotifier>(
      builder: (context, reader, child) {
        return Material(
          color: colorScheme.surface,
          elevation: 4,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Title
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reader.currentBook?.title ?? book.title,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        if (reader.currentBook?.author != null)
                          Text(
                            reader.currentBook!.author!,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),

                  // Chapters button
                  IconButton(
                    icon: Icon(
                      Icons.toc_outlined,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: onChaptersTap,
                    tooltip: 'Chapters',
                  ),

                  // Font size button
                  IconButton(
                    icon: Icon(
                      Icons.format_size_outlined,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: onSettingsTap,
                    tooltip: 'Appearance',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
