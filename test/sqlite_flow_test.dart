import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:routine/main.dart';
import 'package:routine/data/routine_repository.dart';
import 'package:routine/data/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Phase 1 SQLite persistence — seed, insert, query, update', () async {
    final repo = RoutineRepository(
      dbHelper: DatabaseHelper.withName('test_flow.db'),
    );

    // 1. Load seed items
    final items = await repo.getAllItems();
    expect(items.length, greaterThanOrEqualTo(6));
    expect(items.any((i) => i.title.contains('Warm up car')), isTrue);
    expect(items.any((i) => i.title.contains('Morning Briefing')), isTrue);

    // 2. Insert fast log item
    final fastLog = RoutineItem(
      id: 'flow_test_1',
      title: 'Observed soil dryness in garden',
      itemType: 'log',
      category: 'home',
      timeOfDay: 'evening',
      scheduledTime: 'Fast Logged',
      isCompleted: true,
      eventTimestamp: '2026-07-20 06:00 PM',
      recordedAtTimestamp: '2026-07-20 06:05 PM',
      notes: 'Soil moisture low',
    );
    await repo.insertItem(fastLog);

    // 3. Query all items and verify persistence
    final updatedList = await repo.getAllItems();
    expect(updatedList.any((i) => i.id == 'flow_test_1'), isTrue);

    // 4. Update completion status
    await repo.updateItemCompletion('flow_test_1', false);
    final reloadedList = await repo.getAllItems();
    final savedLog = reloadedList.firstWhere((i) => i.id == 'flow_test_1');
    expect(savedLog.isCompleted, isFalse);
  });
}
