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
    final repository = RoutineRepository(dbHelper: DatabaseHelper.withName('test_repo.db'));
    final items = await repository.getAllItems();

    expect(items, isNotEmpty);
    expect(items.any((i) => i.title.contains('Warm up car')), isTrue);
  });

  test('RoutineRepository inserts new log entry and updates completion', () async {
    final repository = RoutineRepository(dbHelper: DatabaseHelper.withName('test_repo.db'));
    final newLog = RoutineItem(
      id: 'test_99',
      title: 'Observed soil dryness in garden',
      itemType: 'log',
      category: 'home',
      timeOfDay: 'evening',
      scheduledTime: 'Fast Logged',
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
  });
}
