import 'package:flutter_test/flutter_test.dart';
import 'package:routine/main.dart';

void main() {
  testWidgets('RoutineApp renders basic title', (WidgetTester tester) async {
    await tester.pumpWidget(const RoutineApp());
    expect(find.textContaining('Routine'), findsOneWidget);
  });
}
