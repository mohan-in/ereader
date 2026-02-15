import 'package:ereader/notifiers/reader_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChaptersSheet extends StatelessWidget {
  const ChaptersSheet({
    required this.onChapterSelected,
    super.key,
  });

  final void Function(String href) onChapterSelected;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Consumer<ReaderNotifier>(
          builder: (context, reader, child) {
            return Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Text(
                    'Table of Contents',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: reader.chapters.isEmpty
                      ? const Center(
                          child: Text(
                            'No chapters found',
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: reader.chapters.length,
                          itemBuilder: (context, index) {
                            final chapter = reader.chapters[index];
                            return ListTile(
                              onTap: () => onChapterSelected(
                                chapter.href,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary
                                      .withValues(
                                        alpha: 0.1,
                                      ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              title: Text(
                                (chapter.title.trim().isNotEmpty
                                        ? chapter.title.trim()
                                        : 'Chapter ${index + 1}')
                                    .replaceAll(
                                      '\n',
                                      ' ',
                                    ),
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
