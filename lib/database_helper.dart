import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// LOGIC: Database operations for study goals
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  // Allow tests to provide a separate database path
  static String? testDatabasePath;

  // Store goals in browser storage
  static const String _webStorageKey = 'study_goals';

  DatabaseHelper._init();

  // LOGIC: Initialize storage for the current platform
  Future<void> initialize() async {
    if (kIsWeb) {
      await SharedPreferences.getInstance();
    } else {
      await database;
    }
  }

  // LOGIC: Get database or initialize it
  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not used on the web platform.');
    }

    if (_database != null) {
      return _database!;
    }

    _database = await initDatabase();
    return _database!;
  }

  // LOGIC: Initialize SQLite database
  Future<Database> initDatabase() async {
    final path = testDatabasePath ?? join(await getDatabasesPath(), 'goals.db');

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

  // Retrieve goals saved in browser storage
  Future<List<Map<String, dynamic>>> _getWebGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGoals = prefs.getString(_webStorageKey);

    if (savedGoals == null) {
      return [];
    }

    final List<dynamic> decodedGoals = jsonDecode(savedGoals);

    return decodedGoals.map((goal) {
      return Map<String, dynamic>.from(goal);
    }).toList();
  }

  // Save goals to browser storage
  Future<void> _saveWebGoals(List<Map<String, dynamic>> goals) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_webStorageKey, jsonEncode(goals));
  }

  // LOGIC: Insert a new goal
  Future<int> insertGoal(Map<String, dynamic> goal) async {
    if (kIsWeb) {
      final goals = await _getWebGoals();

      final newId =
          goals.fold<int>(0, (highest, item) {
            final id = item['id'] as int;
            return id > highest ? id : highest;
          }) +
          1;

      goals.add({
        'id': newId,
        'subject': goal['subject'],
        'hours': goal['hours'],
        'done': goal['done'] == true,
      });

      await _saveWebGoals(goals);
      return newId;
    }

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
    if (kIsWeb) {
      final goals = await _getWebGoals();

      goals.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

      return goals;
    }

    final db = await database;

    final results = await db.query('goals', orderBy: 'id ASC');

    return results.map((goal) {
      return {...goal, 'done': goal['done'] == 1};
    }).toList();
  }

  // LOGIC: Update an existing goal
  Future<int> updateGoal(Map<String, dynamic> goal) async {
    if (kIsWeb) {
      final goals = await _getWebGoals();

      final index = goals.indexWhere((item) => item['id'] == goal['id']);

      if (index == -1) {
        return 0;
      }

      goals[index] = {
        ...goals[index],
        'subject': goal['subject'],
        'hours': goal['hours'],
        'done': goal['done'] == true,
      };

      await _saveWebGoals(goals);
      return 1;
    }

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
    if (kIsWeb) {
      final goals = await _getWebGoals();
      final originalLength = goals.length;

      goals.removeWhere((goal) => goal['id'] == id);

      if (goals.length == originalLength) {
        return 0;
      }

      await _saveWebGoals(goals);
      return 1;
    }

    final db = await database;

    return await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }
}
