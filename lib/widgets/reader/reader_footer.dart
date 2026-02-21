import 'package:ereader/models/book.dart';
import 'package:ereader/notifiers/reader_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReaderFooter extends StatelessWidget {
  const ReaderFooter({
    required this.book,
    required this.themeTextColor,
    super.key,
  });

  final Book book;
  final Color themeTextColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 8,
      child: Consumer<ReaderNotifier>(
        builder: (context, reader, child) {
          final progress = reader.currentLocation?.progress ?? book.progress;
          final chapterTitle = reader.currentChapterTitle;
          final footerColor = themeTextColor.withValues(alpha: 0.6);
          final footerStyle = TextStyle(
            fontSize: 12,
            color: footerColor,
            fontWeight: FontWeight.w500,
          );

          return Row(
            children: [
              // Chapter name (left)
              if (chapterTitle != null)
                Expanded(
                  child: Text(
                    chapterTitle,
                    style: footerStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),

              const SizedBox(width: 8),

              // Progress percentage (right)
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: footerStyle,
              ),
            ],
          );
        },
      ),
    );
  }
}
