import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  final String dbName;
  Database? _database;

  DatabaseHelper._init([this.dbName = 'routine_v4.db']);
  factory DatabaseHelper.withName(String dbName) =>
      DatabaseHelper._init(dbName);

  Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) return existing;
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

    return openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE items (
  id TEXT NOT NULL PRIMARY KEY,
  title TEXT NOT NULL,
  item_type TEXT NOT NULL,
  category TEXT NOT NULL,
  time_of_day TEXT NOT NULL,
  scheduled_time TEXT NOT NULL,
  scheduled_date TEXT,
  event_timestamp TEXT,
  recorded_at_timestamp TEXT,
  is_completed INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  numeric_value REAL,
  unit TEXT,
  prep_offset_minutes INTEGER,
  topic_sources_json TEXT,
  brief_stories_json TEXT
)
''');
    await db.execute(
      'CREATE INDEX idx_items_scheduled_date ON items(scheduled_date)',
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE items ADD COLUMN scheduled_date TEXT');
      await db.execute(
        "UPDATE items SET scheduled_date = strftime('%Y-%m-%d', 'now') "
        'WHERE scheduled_date IS NULL',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_items_scheduled_date ON items(scheduled_date)',
      );
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) await db.close();
    _database = null;
  }
}
