import 'package:andura_ui/andura_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine/main.dart';

void main() {
  testWidgets('RoutineApp renders basic title', (WidgetTester tester) async {
    AnduraTheme.configureFonts(allowRuntimeFetching: false);
    await tester.pumpWidget(const RoutineApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Routine'), findsOneWidget);
  });
}
