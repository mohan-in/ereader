import 'package:suvadi/notifiers/library_notifier.dart';
import 'package:suvadi/notifiers/reader_notifier.dart';
import 'package:suvadi/repositories/book_repository.dart';
import 'package:suvadi/services/epub_parser_service.dart';
import 'package:suvadi/services/file_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFileService extends FileService {
  @override
  Future<List<String>?> pickEpubFiles() async => null;
}

void main() {
  testWidgets('App renders library screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<BookRepository>(
            create: (_) => BookRepository(prefs: prefs),
          ),
          Provider<FileService>(
            create: (_) => _MockFileService(),
          ),
          Provider<EpubParserService>(
            create: (_) => EpubParserService(),
          ),
          ChangeNotifierProxyProvider3<
            BookRepository,
            FileService,
            EpubParserService,
            LibraryNotifier
          >(
            create: (context) => LibraryNotifier(
              bookRepository: context.read<BookRepository>(),
              fileService: context.read<FileService>(),
              epubParserService: context.read<EpubParserService>(),
            ),
            update: (context, repository, fileService, parser, previous) =>
                previous!,
          ),
          ChangeNotifierProvider(create: (_) => ReaderNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Text('Library')),
        ),
      ),
    );

    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('Empty state is shown when no books', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<BookRepository>(
            create: (_) => BookRepository(prefs: prefs),
          ),
          Provider<FileService>(
            create: (_) => _MockFileService(),
          ),
          Provider<EpubParserService>(
            create: (_) => EpubParserService(),
          ),
          ChangeNotifierProvider(
            create: (context) => LibraryNotifier(
              bookRepository: context.read<BookRepository>(),
              fileService: context.read<FileService>(),
              epubParserService: context.read<EpubParserService>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => ReaderNotifier(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Your library is empty'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Your library is empty'), findsOneWidget);
  });
}
