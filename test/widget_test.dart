import 'package:andura_ui/andura_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:routine/main.dart';

void main() {
  testWidgets('RoutineApp renders basic title', (WidgetTester tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AnduraTheme.configureFonts(allowRuntimeFetching: false);
    await tester.pumpWidget(const RoutineApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Routine'), findsAtLeastNWidgets(1));
  });
}
