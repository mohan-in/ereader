import 'dart:async';

import 'package:ereader/models/book.dart';
import 'package:ereader/notifiers/library_notifier.dart';
import 'package:ereader/screens/reader_screen.dart';
import 'package:ereader/widgets/book_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Library screen displaying the user's book collection.
///
/// Shows a grid of books when the library has content, or a simple
/// empty state prompting the user to add their first book.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: Consumer<LibraryNotifier>(
        builder: (context, library, child) {
          if (library.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (library.error != null) {
            return _buildErrorState(context, library.error!);
          }

          if (library.books.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildBookGrid(context, library.books);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => unawaited(
          context.read<LibraryNotifier>().addBookFromPicker(),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  /// Displays an error message with an icon.
  Widget _buildErrorState(
    BuildContext context,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Simple empty state encouraging the user to add a book.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Your library is empty',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first EPUB book',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Grid layout displaying book cards.
  /// Adapts column count based on screen width.
  Widget _buildBookGrid(
    BuildContext context,
    List<Book> books,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minCardWidth = 180.0;
        const spacing = 16.0;
        final availableWidth = constraints.maxWidth - (spacing * 2);
        final columns = (availableWidth / minCardWidth).floor().clamp(2, 6);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 0.55,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return BookCard(
              book: book,
              index: index,
              onTap: () => _openBook(context, book),
              onLongPress: () => _showBookOptions(context, book),
            );
          },
        );
      },
    );
  }

  /// Opens the reader screen for the given book.
  void _openBook(BuildContext context, Book book) {
    final freshBook = context.read<LibraryNotifier>().getBook(book.id) ?? book;

    unawaited(
      Navigator.of(context)
          .push<void>(
            PageRouteBuilder(
              pageBuilder:
                  (
                    context,
                    animation,
                    secondaryAnimation,
                  ) => ReaderScreen(book: freshBook),
              transitionsBuilder:
                  (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
              transitionDuration: const Duration(
                milliseconds: 200,
              ),
            ),
          )
          .then((_) {
            // Trigger rebuild to show updated sort order
            if (mounted) setState(() {});
          }),
    );
  }

  /// Shows options for the selected book.
  void _showBookOptions(BuildContext context, Book book) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  title: const Text(
                    'Remove from library',
                  ),
                  subtitle: const Text(
                    'This cannot be undone',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    unawaited(
                      context.read<LibraryNotifier>().removeBook(book.id),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
