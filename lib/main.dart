import 'dart:async';

import 'package:dex_compat/dex_compat.dart';
import 'package:suvadi/notifiers/library_notifier.dart';
import 'package:suvadi/notifiers/reader_notifier.dart';
import 'package:suvadi/notifiers/theme_notifier.dart';
import 'package:suvadi/repositories/book_repository.dart';
import 'package:suvadi/screens/library_screen.dart';
import 'package:suvadi/services/epub_parser_service.dart';
import 'package:suvadi/services/file_service.dart';
import 'package:suvadi/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDesktopMode = await DexCompat.isDesktopMode();
  runApp(SuvadiApp(prefs: prefs, isDesktopMode: isDesktopMode));
}

class SuvadiApp extends StatelessWidget {
  const SuvadiApp({
    required this.prefs,
    required this.isDesktopMode,
    super.key,
  });

  final SharedPreferences prefs;
  final bool isDesktopMode;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => BookRepository(prefs: prefs)),
        Provider(create: (_) => FileService()),
        Provider(create: (_) => EpubParserService()),
        ChangeNotifierProxyProvider3<
          BookRepository,
          FileService,
          EpubParserService,
          LibraryNotifier
        >(
          create: (context) {
            final notifier = LibraryNotifier(
              bookRepository: context.read<BookRepository>(),
              fileService: context.read<FileService>(),
              epubParserService: context.read<EpubParserService>(),
            );
            unawaited(notifier.init());
            return notifier;
          },
          update: (context, repository, fileService, parser, previous) =>
              previous!,
        ),
        ChangeNotifierProvider(create: (_) => ReaderNotifier()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier(prefs: prefs)),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'Suvadi',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.themeMode,
            home: const LibraryScreen(),
            builder: DexCompat.builder(isDesktopMode),
          );
        },
      ),
    );
  }
}
