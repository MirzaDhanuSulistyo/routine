import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:routine/data/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('database v3 migrates to v6 occurrence storage', () async {
    final name = 'migration_${DateTime.now().microsecondsSinceEpoch}.db';
    final databasePath = path.join(await getDatabasesPath(), name);
    await deleteDatabase(databasePath);
    final oldDatabase = await openDatabase(
      databasePath,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE items (id TEXT NOT NULL PRIMARY KEY)');
      },
    );
    await oldDatabase.close();

    final helper = DatabaseHelper.withName(name);
    final upgraded = await helper.database;
    final tables = await upgraded.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final columns = await upgraded.rawQuery('PRAGMA table_info(items)');
    final names = columns
        .map((column) => column['name']?.toString())
        .whereType<String>()
        .toSet();

    expect(await upgraded.getVersion(), 6);
    expect(tables.map((entry) => entry['name']), contains('item_occurrences'));
    expect(names, contains('repeat_days_json'));
    await helper.close();
    await deleteDatabase(databasePath);
  });

  test('database v4 removes legacy numeric columns', () async {
    final name =
        'measurement_migration_${DateTime.now().microsecondsSinceEpoch}.db';
    final databasePath = path.join(await getDatabasesPath(), name);
    await deleteDatabase(databasePath);
    final oldDatabase = await openDatabase(
      databasePath,
      version: 4,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE items (id TEXT NOT NULL PRIMARY KEY, item_type TEXT, numeric_value REAL, unit TEXT)',
        );
        await db.insert('items', {
          'id': 'legacy',
          'item_type': 'measurement',
          'numeric_value': 5.5,
          'unit': 'hours',
        });
      },
    );
    await oldDatabase.close();

    final helper = DatabaseHelper.withName(name);
    final upgraded = await helper.database;
    final columns = await upgraded.rawQuery('PRAGMA table_info(items)');
    final names = columns
        .map((column) => column['name']?.toString())
        .whereType<String>()
        .toSet();

    expect(await upgraded.getVersion(), 6);
    expect(names, contains('id'));
    expect(names, isNot(contains('numeric_value')));
    expect(names, isNot(contains('unit')));
    expect(names, contains('repeat_days_json'));
    expect((await upgraded.query('items')).single['item_type'], 'log');
    await helper.close();
    await deleteDatabase(databasePath);
  });
}
