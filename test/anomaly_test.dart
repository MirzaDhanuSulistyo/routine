import 'package:flutter_test/flutter_test.dart';
import 'package:routine/main.dart';
import 'package:routine/data/anomaly_engine.dart';

void main() {
  test(
    'AnomalyAnalyticsEngine analyzes routine items for delays and notes',
    () {
      final engine = AnomalyAnalyticsEngine();
      final items = [
        RoutineItem(
          id: 'a1',
          title: 'Clock In to Work',
          itemType: 'reminder',
          category: 'work',
          timeOfDay: 'morning',
          scheduledTime: '08:00 AM',
          eventTimestamp: '2026-07-20 08:15 AM',
          notes: 'Arrived late due to construction',
        ),
        RoutineItem(
          id: 'a2',
          title: 'Morning Briefing',
          itemType: 'briefing',
          category: 'personal',
          timeOfDay: 'morning',
          scheduledTime: '07:00 AM',
          eventTimestamp: '2026-07-20 07:00 AM',
        ),
      ];

      final report = engine.analyze(items);

      expect(report.totalEvents, equals(2));
      expect(report.anomaliesDetected, equals(1));
      expect(report.averageDelayMinutes, equals(7.5));
      expect(
        report.detectedPatterns.any((p) => p.contains('Clock In to Work')),
        isTrue,
      );
    },
  );
}
