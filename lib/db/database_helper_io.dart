import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'coordinates.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE coordinates(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertCoordinate({
    required String timestamp,
    required double latitude,
    required double longitude,
  }) async {
    final db = await database;
    return db.insert('coordinates', {
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<List<Map<String, dynamic>>> getCoordinates() async {
    final db = await database;
    return db.query('coordinates', orderBy: 'id DESC');
  }

  Future<int> deleteCoordinate(int id) async {
    final db = await database;
    return db.delete('coordinates', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateCoordinate({
    required int id,
    required double latitude,
    required double longitude,
  }) async {
    final db = await database;
    return db.update(
      'coordinates',
      {'latitude': latitude, 'longitude': longitude},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}