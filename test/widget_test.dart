import 'package:andura_ui/andura_ui.dart';
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
}
