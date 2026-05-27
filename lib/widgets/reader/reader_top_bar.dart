import 'dart:ui';

import 'package:ereader/models/book.dart';
import 'package:ereader/notifiers/reader_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Top bar for the reader screen with frosted glass effect and bottom border.
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
    return Consumer<ReaderNotifier>(
      builder: (context, reader, child) {
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
                  bottom: BorderSide(
                    color: textColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: textColor,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back to Library',
                      ),

                      // Title & Author details
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reader.currentBook?.title ?? book.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            if (reader.currentBook?.author != null &&
                                reader.currentBook!.author!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                reader.currentBook!.author!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withValues(alpha: 0.65),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Chapters button
                      IconButton(
                        icon: Icon(
                          Icons.toc_rounded,
                          color: textColor,
                          size: 24,
                        ),
                        onPressed: onChaptersTap,
                        tooltip: 'Chapters',
                      ),

                      // Font/Theme Settings button
                      IconButton(
                        icon: Icon(
                          Icons.format_size_rounded,
                          color: textColor,
                          size: 22,
                        ),
                        onPressed: onSettingsTap,
                        tooltip: 'Reader settings',
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
