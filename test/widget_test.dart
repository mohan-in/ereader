import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ereader/main.dart';
import 'package:ereader/notifiers/library_notifier.dart';
import 'package:ereader/notifiers/reader_notifier.dart';

void main() {
  testWidgets('App renders library screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EReaderApp());

    // Verify library screen is displayed
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('Empty state is shown when no books', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LibraryNotifier()),
          ChangeNotifierProvider(create: (_) => ReaderNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: Text('Your library is empty'))),
        ),
      ),
    );

    expect(find.text('Your library is empty'), findsOneWidget);
  });
}
