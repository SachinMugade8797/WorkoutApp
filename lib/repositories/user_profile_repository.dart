import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_profile.dart';

/// Data access layer for structured app data.
///
/// Uses SQLite (via `sqflite`) because we store relational, queryable data
/// (profile, workout history, posture history, subscription status). The
/// legacy module-level flags (streaks, settings toggles, plans) stay in
/// SharedPreferences via [StorageService].
///
/// The database is opened lazily on first use (not at app startup), so the
/// app still boots fine on platforms where the database file can't be opened.
class UserProfileRepository {
  static Database? _database;

  static const int _dbVersion = 1;

  // ---------------------------------------------------------------------------
  // Database open + schema
  // ---------------------------------------------------------------------------

  static Future<Database> _getDatabase() async {
    if (_database != null) return _database!;

    final path = join(await getDatabasesPath(), 'fitforge.db');
    _database = await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
    return _database!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Single-row table: the app has exactly one user profile (id is always 1).
    await db.execute('''
      CREATE TABLE user_profile(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT,
        age INTEGER,
        gender TEXT,
        height REAL,
        weight REAL,
        goal TEXT,
        experience_level TEXT,
        equipment TEXT,
        workout_location TEXT,
        time_per_session TEXT,
        injuries TEXT
      )
    ''');

    // Schema only for now — workout history features come later.
    await db.execute('''
      CREATE TABLE workout_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        duration_minutes INTEGER,
        calories_burned INTEGER,
        exercise_count INTEGER,
        plan_key TEXT
      )
    ''');

    // Schema only for now — posture score features come later.
    await db.execute('''
      CREATE TABLE posture_score_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        score REAL,
        notes TEXT
      )
    ''');

    // Schema only for now — subscription state comes later.
    await db.execute('''
      CREATE TABLE subscription_status(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        is_active INTEGER NOT NULL DEFAULT 0,
        plan TEXT,
        started_at TEXT,
        expires_at TEXT
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  // Profile CRUD
  // ---------------------------------------------------------------------------

  static Future<UserProfile?> getProfile() async {
    final db = await _getDatabase();
    final rows = await db.query('user_profile', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return UserProfile.fromDbMap(rows.first);
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final db = await _getDatabase();
    // conflictAlgorithm.replace = insert-or-update the single id=1 row.
    await db.insert(
      'user_profile',
      profile.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update a single profile field by its model key (e.g. 'name', 'weight').
  ///
  /// If no profile row exists yet, one is created first so the update works
  /// for the very first onboarding step.
  static Future<void> updateField(String key, dynamic value) async {
    final db = await _getDatabase();
    await _ensureProfileRow(db);

    final column = _fieldToColumn(key);
    if (column == null) {
      throw ArgumentError('Unknown profile field: $key');
    }

    Object? dbValue = value;
    if (key == 'injuries') {
      dbValue = value == null ? null : jsonEncode(value);
    }

    await db.update('user_profile', {column: dbValue}, where: 'id = 1');
  }

  /// List of profile field keys that are still unfilled.
  static Future<List<String>> getMissingFields() async {
    final profile = await getProfile();
    if (profile == null) return List.of(UserProfile.allFieldKeys);

    return profile.profileCompletionMap.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Deletes the local profile row (used by "Manage my data").
  static Future<void> deleteProfile() async {
    final db = await _getDatabase();
    await db.delete('user_profile', where: 'id = 1');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static Future<void> _ensureProfileRow(Database db) async {
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM user_profile WHERE id = 1');
    final count = result.first['c'] as int? ?? 0;
    if (count == 0) {
      // Create an empty row so subsequent UPDATE statements have a target.
      await db.insert('user_profile', {'id': 1});
    }
  }

  /// Maps a model field key to the SQLite column name.
  static String? _fieldToColumn(String key) {
    const mapping = <String, String>{
      'name': 'name',
      'age': 'age',
      'gender': 'gender',
      'height': 'height',
      'weight': 'weight',
      'goal': 'goal',
      'experienceLevel': 'experience_level',
      'equipment': 'equipment',
      'workoutLocation': 'workout_location',
      'timePerSession': 'time_per_session',
      'injuries': 'injuries',
    };
    return mapping[key];
  }
}