import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/mood_entry.dart';
import 'local_db_service.dart';

class LocalDbServiceImpl implements LocalDbService {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  @override
  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'moodbloom.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE mood_entries (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            mood TEXT NOT NULL,
            moodCategory TEXT NOT NULL,
            text TEXT,
            attachmentUrl TEXT,
            attachmentType TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            isSynced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  @override
  Future<void> insertMoodEntry(MoodEntry entry) async {
    final db = await database;
    await db.insert(
      'mood_entries',
      entry.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateMoodEntry(MoodEntry entry) async {
    final db = await database;
    await db.update(
      'mood_entries',
      entry.toSqlite(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  @override
  Future<void> deleteMoodEntry(String id) async {
    final db = await database;
    await db.delete('mood_entries', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<MoodEntry>> getMoodEntries(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    final maps = await db.query(
      'mood_entries',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => MoodEntry.fromSqlite(m)).toList();
  }

  @override
  Future<List<MoodEntry>> getUnsyncedEntries(String userId) async {
    final db = await database;
    final maps = await db.query(
      'mood_entries',
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );
    return maps.map((m) => MoodEntry.fromSqlite(m)).toList();
  }

  @override
  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      'mood_entries',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearUserEntries(String userId) async {
    final db = await database;
    await db.delete('mood_entries', where: 'userId = ?', whereArgs: [userId]);
  }

  @override
  Future<void> upsertMoodEntry(MoodEntry entry) async {
    final db = await database;
    await db.insert(
      'mood_entries',
      entry.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
