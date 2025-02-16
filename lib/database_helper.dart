import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:barqr_manager/scanned_result.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  Future<void> bulkInsert(List<ScannedResult> results) async {
    final db = await database;
    final batch = db.batch();

    for (final result in results) {
      batch.insert(
        'scanned_results',
        result.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }
  Future<Database> _initDatabase() async {
    String path = await getDatabasesPath() + 'scanned_results.db';
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE scanned_results ADD COLUMN format TEXT DEFAULT \'\'');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE scanned_results ADD COLUMN title TEXT DEFAULT \'\'');
    }
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scanned_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        data TEXT NOT NULL,
        format TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<void> deleteScannedResult(int id) async {
    Database db = await database;
    await db.delete(
      'scanned_results',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertScannedResult(ScannedResult result) async {
    Database db = await database;
    return await db.insert(
      'scanned_results',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScannedResult>> getScannedResults() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'scanned_results',
      orderBy: 'timestamp DESC',  // New: Order by timestamp descending
    );
    return List.generate(maps.length, (i) {
      return ScannedResult.fromMap(maps[i]);
    });
  }

  // New: Add bulk delete functionality
  Future<int> deleteAllResults() async {
    Database db = await database;
    return await db.delete('scanned_results');
  }

  // New: Add search functionality
  Future<List<ScannedResult>> searchResults(String query) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'scanned_results',
      where: 'title LIKE ? OR data LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => ScannedResult.fromMap(maps[i]));
  }
}