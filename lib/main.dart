import 'dart:async';

import 'package:ereader/notifiers/library_notifier.dart';
import 'package:ereader/notifiers/reader_notifier.dart';
import 'package:ereader/screens/library_screen.dart';
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
        ChangeNotifierProvider(
          create: (_) {
            final notifier = LibraryNotifier();
            unawaited(notifier.init());
            return notifier;
          },
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
