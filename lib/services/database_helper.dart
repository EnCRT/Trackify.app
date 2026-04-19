import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/vehicle.dart';
import '../models/session.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'moto_lap_timer.db');
    return await openDatabase(
      path,
      version: 10, // v10: store user global stats
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nickname TEXT Not NULL,
        firstName TEXT Not NULL,
        lastName TEXT Not NULL,
        joinDate TEXT Not NULL,
        totalDistanceMeters REAL NOT NULL DEFAULT 0,
        totalTimeMillis INTEGER NOT NULL DEFAULT 0,
        sessionsCount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE vehicles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand TEXT Not NULL,
        model TEXT Not NULL,
        year INTEGER Not NULL,
        isFavorite INTEGER Not NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER Not NULL,
        date TEXT Not NULL,
        locationName TEXT Not NULL,
        durationMillis INTEGER Not NULL,
        totalDistanceMeters REAL Not NULL,
        routePointsJson TEXT Not NULL,
        routeSpeedsJson TEXT Not NULL,
        routeTimestampsJson TEXT NOT NULL DEFAULT '[]',
        importDate TEXT Not NULL,
        lapsJson TEXT NOT NULL DEFAULT '[]',
        sectorGatesJson TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add users table if upgrading from version 1
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nickname TEXT Not NULL,
          firstName TEXT Not NULL,
          lastName TEXT Not NULL,
          joinDate TEXT Not NULL,
          totalDistanceMeters REAL NOT NULL DEFAULT 0,
          totalTimeMillis INTEGER NOT NULL DEFAULT 0,
          sessionsCount INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE sessions ADD COLUMN routeSpeedsJson TEXT NOT NULL DEFAULT '[]'
      ''');
    }
    if (oldVersion < 4) {
      // For migration, we use the session 'date' as the default 'importDate'
      await db.execute('''
        ALTER TABLE sessions ADD COLUMN importDate TEXT NOT NULL DEFAULT ''
      ''');
      // Set importDate = date for existing sessions to avoid empty strings
      await db.execute('''
        UPDATE sessions SET importDate = date WHERE importDate = ''
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        ALTER TABLE sessions ADD COLUMN lapsJson TEXT NOT NULL DEFAULT '[]'
      ''');
      await db.execute('''
        ALTER TABLE sessions ADD COLUMN sectorPointsJson TEXT NOT NULL DEFAULT '[]'
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        ALTER TABLE sessions ADD COLUMN routeTimestampsJson TEXT NOT NULL DEFAULT '[]'
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('''
        ALTER TABLE sessions ADD COLUMN sectorGatesJson TEXT NOT NULL DEFAULT '[]'
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('''
        ALTER TABLE vehicles ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0
      ''');
    }
    if (oldVersion < 9) {
      await db.execute('DROP TABLE IF EXISTS lap_sectors');
    }
    if (oldVersion < 10) {
      await db.execute('''
        ALTER TABLE users ADD COLUMN totalDistanceMeters REAL NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE users ADD COLUMN totalTimeMillis INTEGER NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE users ADD COLUMN sessionsCount INTEGER NOT NULL DEFAULT 0
      ''');
    }
  }

  // --- Users ---
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUser() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      limit: 1,
    ); // We only expect 1 user
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateUserStats({
    required int userId,
    required double totalDistanceMeters,
    required int totalTimeMillis,
    required int sessionsCount,
  }) async {
    final db = await database;
    await db.update(
      'users',
      {
        'totalDistanceMeters': totalDistanceMeters,
        'totalTimeMillis': totalTimeMillis,
        'sessionsCount': sessionsCount,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<({double totalDistanceMeters, int totalTimeMillis, int sessionsCount})>
      getSessionsAggregate() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as sessionsCount,
        COALESCE(SUM(totalDistanceMeters), 0) as totalDistanceMeters,
        COALESCE(SUM(durationMillis), 0) as totalTimeMillis
      FROM sessions
    ''');

    final row = result.first;
    return (
      totalDistanceMeters: (row['totalDistanceMeters'] as num).toDouble(),
      totalTimeMillis: (row['totalTimeMillis'] as num).toInt(),
      sessionsCount: (row['sessionsCount'] as num).toInt(),
    );
  }

  // --- Vehicles ---
  Future<int> insertVehicle(Vehicle vehicle) async {
    Database db = await database;
    return await db.insert('vehicles', vehicle.toMap());
  }

  Future<List<Vehicle>> getVehicles() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vehicles');
    return List.generate(maps.length, (i) => Vehicle.fromMap(maps[i]));
  }

  Future<void> setVehicleFavorite(int vehicleId) async {
    Database db = await database;
    await db.transaction((txn) async {
      // Unset all favorites
      await txn.update('vehicles', {'isFavorite': 0});
      // Set target as favorite
      await txn.update(
        'vehicles',
        {'isFavorite': 1},
        where: 'id = ?',
        whereArgs: [vehicleId],
      );
    });
  }

  // --- Sessions ---
  Future<int> insertSession(Session session) async {
    Database db = await database;
    return await db.insert('sessions', session.toMap());
  }

  Future<List<Session>> getSessions() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      orderBy: 'importDate DESC',
    );
    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  Future<List<Session>> getSessionsForVehicle(int vehicleId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'importDate DESC',
    );
    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  Future<void> deleteSession(int id) async {
    Database db = await database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSession(Session session) async {
    Database db = await database;
    await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }
}
