import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:routine/main.dart';
import 'package:routine/data/routine_repository.dart';
import 'package:routine/data/database_helper.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('RoutineRepository initializes and seeds default items', () async {
    final repository = RoutineRepository(
      dbHelper: DatabaseHelper.withName('test_repo.db'),
    );
    final items = await repository.getAllItems();

    expect(items, isNotEmpty);
    expect(items.any((i) => i.title.contains('Warm up car')), isTrue);
  });

  test(
    'RoutineRepository inserts new log entry and updates completion',
    () async {
      final repository = RoutineRepository(
        dbHelper: DatabaseHelper.withName('test_repo.db'),
      );
      final newLog = RoutineItem(
        id: 'test_99',
        title: 'Observed soil dryness in garden',
        itemType: 'log',
        category: 'home',
        timeOfDay: 'evening',
        scheduledTime: '09:00 PM',
        scheduledDate: '2026-07-20',
        recurrenceRule: 'daily',
        notificationsEnabled: true,
        isCompleted: true,
        eventTimestamp: 'Today 06:00 PM',
        recordedAtTimestamp: 'Today 06:05 PM',
        notes: 'Soil moisture low',
      );

      await repository.insertItem(newLog);
      var items = await repository.getAllItems();
      expect(items.any((i) => i.id == 'test_99'), isTrue);

      await repository.updateItemCompletion('test_99', false);
      items = await repository.getAllItems();
      final updated = items.firstWhere((i) => i.id == 'test_99');
      expect(updated.isCompleted, isFalse);
      expect(updated.recurrenceRule, 'daily');
      expect(updated.notificationsEnabled, isTrue);
    },
  );

  test('named databases are isolated and restore replaces user data', () async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final firstHelper = DatabaseHelper.withName('test_first_$suffix.db');
    final secondHelper = DatabaseHelper.withName('test_second_$suffix.db');
    final first = RoutineRepository(dbHelper: firstHelper);
    final second = RoutineRepository(dbHelper: secondHelper);
    final today = DateTime.now();
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    await first.resetToSeedItems(date: today);
    await second.resetToSeedItems(date: today);
    await first.insertItem(
      RoutineItem(
        id: 'first_only',
        title: 'First database only',
        itemType: 'task',
        category: 'personal',
        timeOfDay: 'morning',
        scheduledTime: '09:00 AM',
        scheduledDate: dateKey,
      ),
    );

    expect(
      (await first.getAllItems()).any((i) => i.id == 'first_only'),
      isTrue,
    );
    expect(
      (await second.getAllItems()).any((i) => i.id == 'first_only'),
      isFalse,
    );

    await first.resetToSeedItems(date: today);
    final restored = await first.getAllItems();
    expect(restored, hasLength(6));
    expect(restored.any((i) => i.id == 'first_only'), isFalse);
    expect(await first.getItemsForDate(today), hasLength(6));

    await firstHelper.close();
    await secondHelper.close();
  });
}
