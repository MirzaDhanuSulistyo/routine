import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final String dbName;

  DatabaseHelper._init([this.dbName = 'routine_v4.db']);
  factory DatabaseHelper.withName(String dbName) => DatabaseHelper._init(dbName);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    try {
      final dbDir = await getApplicationDocumentsDirectory();
      path = join(dbDir.path, filePath);
    } catch (_) {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL DEFAULT 0';
    const realNullable = 'REAL';
    const intNullable = 'INTEGER';

    await db.execute('''
CREATE TABLE items (
  id $textType PRIMARY KEY,
  title $textType,
  item_type $textType,
  category $textType,
  time_of_day $textType,
  scheduled_time $textType,
  event_timestamp $textNullable,
  recorded_at_timestamp $textNullable,
  is_completed $intType,
  notes $textNullable,
  numeric_value $realNullable,
  unit $textNullable,
  prep_offset_minutes $intNullable,
  topic_sources_json $textNullable,
  brief_stories_json $textNullable
)
''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
