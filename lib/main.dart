import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'notifiers/library_notifier.dart';
import 'notifiers/reader_notifier.dart';
import 'screens/library_screen.dart';
import 'theme/app_theme.dart';

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
        ChangeNotifierProvider(create: (_) => LibraryNotifier()..init()),
        ChangeNotifierProvider(create: (_) => ReaderNotifier()),
      ],
      child: MaterialApp(
        title: 'eReader',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const LibraryScreen(),
      ),
    );
  }
}
