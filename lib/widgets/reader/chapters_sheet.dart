import 'package:suvadi/notifiers/reader_notifier.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Consumer<ReaderNotifier>(
          builder: (context, reader, child) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Table of Contents',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
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
                            physics: const BouncingScrollPhysics(),
                            itemCount: reader.chapters.length,
                            itemBuilder: (context, index) {
                              final chapter = reader.chapters[index];
                              final rawTitle = chapter.title.trim().isNotEmpty
                                  ? chapter.title.trim()
                                  : 'Chapter ${index + 1}';
                              final cleanTitle = rawTitle.replaceAll('\n', ' ');

                              // Match active status using the resolved current
                              // chapter title
                              final isActive =
                                  reader.currentChapterTitle != null &&
                                  (reader.currentChapterTitle == cleanTitle ||
                                      reader.currentChapterTitle!.contains(
                                        cleanTitle,
                                      ) ||
                                      cleanTitle.contains(
                                        reader.currentChapterTitle!,
                                      ));

                              return ListTile(
                                onTap: () => onChapterSelected(chapter.href),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 4,
                                ),
                                selected: isActive,
                                selectedTileColor: colorScheme.primaryContainer
                                    .withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? colorScheme.primary
                                        : colorScheme.primary.withValues(
                                            alpha: 0.08,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isActive
                                          ? colorScheme.onPrimary
                                          : colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  cleanTitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isActive
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
