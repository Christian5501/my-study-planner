
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// LOGIC: Database operations for study goals
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  // Allow tests to provide a separate database path
  static String? testDatabasePath;

  DatabaseHelper._init();

  // LOGIC: Get database or initialize it
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await initDatabase();
    return _database!;
  }

  // LOGIC: Initialize SQLite database
  Future<Database> initDatabase() async {
    final path = testDatabasePath ??
        join(await getDatabasesPath(), 'goals.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject TEXT NOT NULL,
            hours INTEGER NOT NULL,
            done INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // LOGIC: Insert a new goal
  Future<int> insertGoal(Map<String, dynamic> goal) async {
    final db = await database;

    final goalData = {
      'subject': goal['subject'],
      'hours': goal['hours'],
      'done': goal['done'] == true ? 1 : 0,
    };

    return await db.insert('goals', goalData);
  }

  // LOGIC: Retrieve all saved goals
  Future<List<Map<String, dynamic>>> getGoals() async {
    final db = await database;

    final results = await db.query('goals', orderBy: 'id ASC');

    return results.map((goal) {
      return {
        ...goal,
        'done': goal['done'] == 1,
      };
    }).toList();
  }

  // LOGIC: Update an existing goal
  Future<int> updateGoal(Map<String, dynamic> goal) async {
    final db = await database;

    final goalData = {
      'subject': goal['subject'],
      'hours': goal['hours'],
      'done': goal['done'] == true ? 1 : 0,
    };

    return await db.update(
      'goals',
      goalData,
      where: 'id = ?',
      whereArgs: [goal['id']],
    );
  }

  // LOGIC: Delete a goal
  Future<int> deleteGoal(int id) async {
    final db = await database;

    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
