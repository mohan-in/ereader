import 'dart:async';

import 'package:ereader/notifiers/library_notifier.dart';
import 'package:ereader/notifiers/reader_notifier.dart';
import 'package:ereader/repositories/book_repository.dart';
import 'package:ereader/screens/library_screen.dart';
import 'package:ereader/services/file_service.dart';
import 'package:ereader/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EReaderApp());
}

class EReaderApp extends StatelessWidget {
  const EReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (_) => BookRepository(),
        ),
        Provider(
          create: (_) => FileService(),
        ),
        ChangeNotifierProxyProvider2<
          BookRepository,
          FileService,
          LibraryNotifier
        >(
          create: (context) {
            final notifier = LibraryNotifier(
              bookRepository: context.read<BookRepository>(),
              fileService: context.read<FileService>(),
            );
            unawaited(notifier.init());
            return notifier;
          },
          update: (context, repository, fileService, previous) => previous!,
        ),
        ChangeNotifierProvider(
          create: (_) => ReaderNotifier(),
        ),
      ],
      child: MaterialApp(
        title: 'eReader',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const LibraryScreen(),
      ),
    );
  }
}
