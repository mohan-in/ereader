import 'package:ereader/models/book.dart';
import 'package:ereader/notifiers/reader_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Top bar for the reader screen with title, back button,
/// and action buttons.
class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    required this.book,
    required this.onChaptersTap,
    required this.onSettingsTap,
    super.key,
  });

  final Book book;
  final VoidCallback onChaptersTap;
  final VoidCallback onSettingsTap;

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
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 8,
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Title
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reader.currentBook?.title ?? book.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        if (reader.currentBook?.author != null)
                          Text(
                            reader.currentBook!.author!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
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
