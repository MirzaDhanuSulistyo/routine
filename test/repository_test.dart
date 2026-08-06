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

  test(
    'stores per-date completion history and cascades item deletion',
    () async {
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final helper = DatabaseHelper.withName('test_occurrences_$suffix.db');
      final repository = RoutineRepository(dbHelper: helper);
      await repository.resetToSeedItems(date: DateTime(2026, 7, 20));
      final recurring = RoutineItem(
        id: 'daily_water',
        title: 'Water plants',
        itemType: 'maintenance',
        category: 'home',
        timeOfDay: 'morning',
        scheduledTime: '08:00 AM',
        scheduledDate: '2026-07-20',
        recurrenceRule: 'daily',
      );
      await repository.insertItem(recurring);

      await repository.setOccurrenceCompletion(
        itemId: recurring.id,
        occurrenceDate: '2026-07-20',
        isCompleted: true,
        eventTime: DateTime(2026, 7, 20, 8, 5),
      );
      await repository.setOccurrenceCompletion(
        itemId: recurring.id,
        occurrenceDate: '2026-07-21',
        isCompleted: true,
      );
      await repository.setOccurrenceCompletion(
        itemId: recurring.id,
        occurrenceDate: '2026-07-21',
        isCompleted: false,
      );

      final occurrences = await repository.getAllOccurrences();
      expect(
        occurrences.where((entry) => entry.itemId == recurring.id),
        hasLength(1),
      );
      expect(
        (await repository.getOccurrence(
          recurring.id,
          '2026-07-20',
        ))?.isCompleted,
        isTrue,
      );
      expect(
        await repository.getOccurrence(recurring.id, '2026-07-21'),
        isNull,
      );

      await repository.insertItem(
        recurring.copyWith(title: 'Water all plants'),
      );
      expect(
        (await repository.getOccurrence(
          recurring.id,
          '2026-07-20',
        ))?.isCompleted,
        isTrue,
      );
      final firstDay = await repository.getItemsForDate(DateTime(2026, 7, 20));
      final secondDay = await repository.getItemsForDate(DateTime(2026, 7, 21));
      expect(
        firstDay.firstWhere((item) => item.id == recurring.id).isCompleted,
        isTrue,
      );
      expect(
        secondDay.firstWhere((item) => item.id == recurring.id).isCompleted,
        isFalse,
      );

      await repository.deleteItem(recurring.id);
      expect(await repository.getItemById(recurring.id), isNull);
      expect(
        (await repository.getAllOccurrences()).where(
          (entry) => entry.itemId == recurring.id,
        ),
        isEmpty,
      );
      await helper.close();
    },
  );

  test('daily repeat days and monthly recurrence project correctly', () async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final helper = DatabaseHelper.withName('test_recurrence_$suffix.db');
    final repository = RoutineRepository(dbHelper: helper);

    // 2026-07-20 is a Monday; repeat on Mon(1), Wed(3), Fri(5).
    final weekdayOnly = RoutineItem(
      id: 'weekday_only',
      title: 'Weekday practice',
      itemType: 'task',
      category: 'family',
      timeOfDay: 'evening',
      scheduledTime: '07:00 PM',
      scheduledDate: '2026-07-20',
      recurrenceRule: 'daily',
      repeatDays: [1, 3, 5],
    );
    final billPay = RoutineItem(
      id: 'bill_pay',
      title: 'Pay bills',
      itemType: 'reminder',
      category: 'finance',
      timeOfDay: 'morning',
      scheduledTime: '09:00 AM',
      scheduledDate: '2026-07-20',
      recurrenceRule: 'monthly',
    );
    await repository.insertItem(weekdayOnly);
    await repository.insertItem(billPay);

    final persisted = await repository.getItemById('weekday_only');
    expect(persisted!.repeatDays, [1, 3, 5]);

    // Mon 2026-07-20, Tue 2026-07-21, Wed 2026-07-22, Fri 2026-07-24.
    expect(
      (await repository.getItemsForDate(
        DateTime(2026, 7, 20),
      )).any((i) => i.id == 'weekday_only'),
      isTrue,
    );
    expect(
      (await repository.getItemsForDate(
        DateTime(2026, 7, 21),
      )).any((i) => i.id == 'weekday_only'),
      isFalse,
    );
    expect(
      (await repository.getItemsForDate(
        DateTime(2026, 7, 22),
      )).any((i) => i.id == 'weekday_only'),
      isTrue,
    );
    expect(
      (await repository.getItemsForDate(
        DateTime(2026, 7, 24),
      )).any((i) => i.id == 'weekday_only'),
      isTrue,
    );

    expect(
      (await repository.getItemsForDate(
        DateTime(2026, 7, 20),
      )).any((i) => i.id == 'bill_pay'),
      isTrue,
    );
    expect(
      (await repository.getItemsForDate(
        DateTime(2026, 8, 20),
      )).any((i) => i.id == 'bill_pay'),
      isTrue,
    );
    expect(
      (await repository.getItemsForDate(
        DateTime(2026, 8, 21),
      )).any((i) => i.id == 'bill_pay'),
      isFalse,
    );

    await helper.close();
  });

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
