import 'package:andura_ui/andura_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:routine/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AnduraTheme.configureFonts(allowRuntimeFetching: false);
  });

  testWidgets('RoutineApp renders basic title', (WidgetTester tester) async {
    await tester.pumpWidget(const RoutineApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Routine'), findsAtLeastNWidgets(1));
  });

  testWidgets('item builder opens from the app bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoutineApp());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Create routine item'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Create Routine Item'), findsOneWidget);
    expect(find.text('Create Item'), findsOneWidget);
  });

  testWidgets('item builder keeps controllers alive through exit animation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigationScreen(
          themeMode: ThemeMode.dark,
          onToggleTheme: () {},
          initialItems: const [],
        ),
      ),
    );

    await tester.tap(find.byTooltip('Create routine item'));
    await tester.pumpAndSettle();
    await tester.pageBack();

    // The dialog route still builds while its exit animation is running.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('fast log records observations without numeric fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigationScreen(
          themeMode: ThemeMode.dark,
          onToggleTheme: () {},
          initialItems: const [],
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Quick Log'));
    await tester.pump();

    expect(find.text('Fast Event & Observation Logger'), findsOneWidget);
    expect(find.text('Numeric Value'), findsNothing);
    expect(find.text('Unit Label'), findsNothing);
  });

  testWidgets('alarm screen is full-screen and exposes stop and snooze', (
    WidgetTester tester,
  ) async {
    var stopped = false;
    var snoozed = false;
    final item = RoutineItem(
      id: 'alarm-screen',
      title: 'Leave for work',
      itemType: 'reminder',
      category: 'work',
      timeOfDay: 'morning',
      scheduledTime: '08:00 AM',
      notificationsEnabled: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RoutineAlarmScreen(
          item: item,
          onSnooze: () async => snoozed = true,
          onStop: () async => stopped = true,
        ),
      ),
    );

    expect(find.text('ROUTINE ALARM'), findsOneWidget);
    expect(find.text('Leave for work'), findsOneWidget);
    expect(find.text('Snooze 10m'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(
      find.text('Always vibrates • sound follows your phone setting'),
      findsOneWidget,
    );

    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(stopped, isTrue);
    expect(snoozed, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('timeline item exposes edit and delete dialogs', (
    WidgetTester tester,
  ) async {
    final today = DateTime.now();
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final item = RoutineItem(
      id: 'editable',
      title: 'Editable task',
      itemType: 'task',
      category: 'personal',
      timeOfDay: 'morning',
      scheduledTime: '09:00 AM',
      scheduledDate: dateKey,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigationScreen(
          themeMode: ThemeMode.dark,
          onToggleTheme: () {},
          initialItems: [item],
        ),
      ),
    );
    await tester.pump();

    final actions = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.more_vert),
        matching: find.byType(IconButton),
      ),
    );
    actions.onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    await tester.tap(find.text('Edit'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Edit Routine Item'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 300));
    final refreshedActions = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.more_vert),
        matching: find.byType(IconButton),
      ),
    );
    refreshedActions.onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Delete routine item?'), findsOneWidget);
    expect(find.textContaining('stored data will be removed'), findsOneWidget);
  });
}
