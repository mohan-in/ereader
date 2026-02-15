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
      right: 16,
      bottom: 8,
      child: Consumer<ReaderNotifier>(
        builder: (context, reader, child) {
          final progress = reader.currentLocation?.progress ?? book.progress;
          return Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              color: themeTextColor.withValues(
                alpha: 0.6,
              ),
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
    );
  }
}
