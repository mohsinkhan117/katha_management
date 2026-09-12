import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalLogoService {
  static final LocalLogoService _instance = LocalLogoService._internal();

  factory LocalLogoService() => _instance;

  LocalLogoService._internal();

  Database? _database;

  static const String _databaseName = 'hotel_local.db';
  static const int _databaseVersion = 1;

  static const String _tableName = 'hotel_logo';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();

    final databasePath = path.join(databasesPath, _databaseName);

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY,
            logo_path TEXT
          )
        ''');
      },
    );
  }

  // SAVE LOGO PATH

  Future<void> saveLogoPath(String logoPath) async {
    final db = await database;

    await db.insert(_tableName, {
      'id': 1,
      'logo_path': logoPath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // GET LOGO PATH

  Future<String?> getLogoPath() async {
    final db = await database;

    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first['logo_path'] as String?;
  }

  // DELETE LOGO

  Future<void> deleteLogo() async {
    final db = await database;

    final logoPath = await getLogoPath();

    if (logoPath != null) {
      final file = File(logoPath);

      if (await file.exists()) {
        await file.delete();
      }
    }

    await db.delete(_tableName, where: 'id = ?', whereArgs: [1]);
  }

  // SAVE IMAGE FILE LOCALLY

  Future<String> saveLogoFile(File sourceFile) async {
    final directory = await getApplicationDocumentsDirectory();

    final logoDirectory = Directory(path.join(directory.path, 'hotel'));

    if (!await logoDirectory.exists()) {
      await logoDirectory.create(recursive: true);
    }

    final logoPath = path.join(logoDirectory.path, 'hotel_logo.jpg');

    final destinationFile = File(logoPath);

    // Delete old logo if it exists.
    if (await destinationFile.exists()) {
      await destinationFile.delete();
    }

    await sourceFile.copy(logoPath);

    await saveLogoPath(logoPath);

    return logoPath;
  }
}
