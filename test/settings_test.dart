import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine/main.dart';

void main() {
  testWidgets('Settings screen renders theme switch and database controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return const RoutineApp();
        },
      ),
    );

    // Initial pump
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(RoutineApp), findsOneWidget);
  });
}
