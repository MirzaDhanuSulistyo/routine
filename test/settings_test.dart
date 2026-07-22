import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:routine/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Settings screen renders theme switch and database controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigationScreen(
          themeMode: ThemeMode.dark,
          onToggleTheme: () {},
          initialItems: const [],
          initialIndex: 2,
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Native Reminders'), findsOneWidget);
    expect(find.text('Local SQLite Database'), findsOneWidget);
    expect(find.text('Enable Notification Permissions'), findsOneWidget);
  });
}
