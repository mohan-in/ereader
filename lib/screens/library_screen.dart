import 'dart:async';

import 'package:suvadi/models/book.dart';
import 'package:suvadi/notifiers/library_notifier.dart';
import 'package:suvadi/notifiers/theme_notifier.dart';
import 'package:suvadi/screens/reader_screen.dart';
import 'package:suvadi/widgets/book_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Library screen displaying the user's book collection.
///
/// Features highly-optimized rendering using granular state Selectors to
/// prevent layout rebuilds during background progress synchronization.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'reading', 'finished'
  String _sortBy = 'recent'; // 'recent', 'title', 'progress'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Selector for global loading state to prevent body redraws
    final isLoading = context.select<LibraryNotifier, bool>((n) => n.isLoading);
    if (isLoading) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. Selector for global error state
    final error = context.select<LibraryNotifier, String?>((n) => n.error);
    if (error != null) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: _buildErrorState(context, error),
      );
    }

    // 3. Selector for actual book count (empty library state)
    final hasBooks = context.select<LibraryNotifier, bool>(
      (n) => n.books.isNotEmpty,
    );
    if (!hasBooks) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: _buildEmptyState(context, isFilterEmpty: false),
        floatingActionButton: _buildFAB(context),
      );
    }

    // 4. Main grid display with search & filters
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchAndFilters(context),
          Expanded(
            child: _buildBookGridWithSelector(),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: const Text('My Library'),
      actions: [
        Consumer<ThemeNotifier>(
          builder: (context, themeNotifier, child) {
            IconData themeIcon;
            switch (themeNotifier.themeMode) {
              case ThemeMode.light:
                themeIcon = Icons.light_mode_rounded;
              case ThemeMode.dark:
                themeIcon = Icons.dark_mode_rounded;
              case ThemeMode.system:
                themeIcon = Icons.brightness_medium_rounded;
            }

            return PopupMenuButton<ThemeMode>(
              icon: Icon(themeIcon, color: colorScheme.onSurfaceVariant),
              tooltip: 'App Theme',
              initialValue: themeNotifier.themeMode,
              onSelected: themeNotifier.updateThemeMode,
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  value: ThemeMode.system,
                  checked: themeNotifier.themeMode == ThemeMode.system,
                  child: const Text('System Default'),
                ),
                CheckedPopupMenuItem(
                  value: ThemeMode.light,
                  checked: themeNotifier.themeMode == ThemeMode.light,
                  child: const Text('Light Theme'),
                ),
                CheckedPopupMenuItem(
                  value: ThemeMode.dark,
                  checked: themeNotifier.themeMode == ThemeMode.dark,
                  child: const Text('Dark Theme'),
                ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => unawaited(
        context.read<LibraryNotifier>().addBookFromPicker(),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Book'),
    );
  }

  /// Builds search text field, choice chips, and sorting button.
  Widget _buildSearchAndFilters(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Box
          SearchBar(
            controller: _searchController,
            hintText: 'Search your collection...',
            leading: Icon(
              Icons.search_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            trailing: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: _searchController.clear,
                ),
            ],
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(
              colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Filters and Sort Row
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _filterType == 'all',
                        onSelected: (selected) {
                          if (selected) setState(() => _filterType = 'all');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Reading'),
                        selected: _filterType == 'reading',
                        onSelected: (selected) {
                          if (selected) setState(() => _filterType = 'reading');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Finished'),
                        selected: _filterType == 'finished',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filterType = 'finished');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Sort Options Trigger
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sortBy == 'recent'
                            ? 'Recent'
                            : _sortBy == 'title'
                            ? 'Title'
                            : 'Progress',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                tooltip: 'Sort collection',
                initialValue: _sortBy,
                onSelected: (value) {
                  setState(() {
                    _sortBy = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'recent',
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Recent'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'title',
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Title'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'progress',
                    child: Row(
                      children: [
                        Icon(Icons.donut_large_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Progress'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Displays an error message with an icon.
  Widget _buildErrorState(
    BuildContext context,
    String error,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Redesigned premium empty states.
  Widget _buildEmptyState(BuildContext context, {required bool isFilterEmpty}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isFilterEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No matching books',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search query or filters',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _filterType = 'all';
                  });
                },
                icon: const Icon(Icons.filter_list_off_rounded),
                label: const Text('Reset filters'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.library_books_rounded,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Library is Empty',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Import EPUB books to your collection and start reading '
                'with custom styles, progress syncing, and more.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => unawaited(
                  context.read<LibraryNotifier>().addBookFromPicker(),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Import a Book'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the book grid using a Selector on filtered book IDs.
  ///
  /// Prevents full grid rebuilds when individual book reading progress updates.
  Widget _buildBookGridWithSelector() {
    return Selector<LibraryNotifier, List<String>>(
      selector: (context, library) {
        var processedBooks = List<Book>.from(library.books);

        // 1. Search Query filter
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          processedBooks = processedBooks.where((book) {
            final title = book.title.toLowerCase();
            final author = book.author?.toLowerCase() ?? '';
            return title.contains(query) || author.contains(query);
          }).toList();
        }

        // 2. Status filter
        if (_filterType == 'reading') {
          processedBooks = processedBooks
              .where((book) => book.progress > 0 && book.progress < 0.99)
              .toList();
        } else if (_filterType == 'finished') {
          processedBooks = processedBooks
              .where((book) => book.progress >= 0.99)
              .toList();
        }

        // 3. Sort ordering
        if (_sortBy == 'title') {
          processedBooks.sort((a, b) => a.title.compareTo(b.title));
        } else if (_sortBy == 'progress') {
          processedBooks.sort((a, b) => b.progress.compareTo(a.progress));
        }

        return processedBooks.map((b) => b.id).toList();
      },
      shouldRebuild: (prev, next) => !listEquals(prev, next),
      builder: (context, bookIds, child) {
        if (bookIds.isEmpty) {
          return _buildEmptyState(context, isFilterEmpty: true);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            const minCardWidth = 160.0;
            const spacing = 16.0;
            final availableWidth = constraints.maxWidth - (spacing * 2);
            final columns = (availableWidth / minCardWidth).floor().clamp(2, 6);

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 0.58,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: bookIds.length,
              itemBuilder: (context, index) {
                final bookId = bookIds[index];
                return _BookCardSelectorWrapper(
                  bookId: bookId,
                  index: index,
                  onTap: (book) => _openBook(context, book),
                  onMenuTap: (book) => _showBookOptions(context, book),
                );
              },
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
                milliseconds: 250,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (book.author != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          book.author!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: colorScheme.error,
                    ),
                  ),
                  title: Text(
                    'Remove from library',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                  ),
                  subtitle: const Text(
                    'This deletes the book file permanently',
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

/// Selector wrapper for individual book cards to prevent redrawing the entire
/// grid.
class _BookCardSelectorWrapper extends StatelessWidget {
  const _BookCardSelectorWrapper({
    required this.bookId,
    required this.index,
    required this.onTap,
    required this.onMenuTap,
  });

  final String bookId;
  final int index;
  final void Function(Book) onTap;
  final void Function(Book) onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Selector<LibraryNotifier, Book?>(
      selector: (_, notifier) => notifier.getBook(bookId),
      builder: (context, book, child) {
        if (book == null) return const SizedBox.shrink();
        return BookCard(
          book: book,
          index: index,
          onTap: () => onTap(book),
          onLongPress: () => onMenuTap(book),
          onMenuTap: () => onMenuTap(book),
        );
      },
    );
  }
}
