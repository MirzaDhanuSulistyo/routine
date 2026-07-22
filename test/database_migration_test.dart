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

  test('database v3 migrates to v4 occurrence storage', () async {
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

    expect(await upgraded.getVersion(), 4);
    expect(tables.map((entry) => entry['name']), contains('item_occurrences'));
    await helper.close();
    await deleteDatabase(databasePath);
  });
}
