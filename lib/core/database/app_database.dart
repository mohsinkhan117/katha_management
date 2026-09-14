// lib/core/database/app_database.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Single sqflite entry point for the whole app.
///
/// Every feature's repository asks this class for the `Database`
/// instance rather than opening its own connection. Table creation for
/// new features is added here, guarded by a version bump in
/// `_onUpgrade`, so the schema grows without breaking existing data.
class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  static Database? _database;

  // Bump this and add a branch in `_onUpgrade` whenever a table is
  // added or changed (e.g. Party, Product, Payment modules).
  static const int _dbVersion = 1;
  static const String _dbName = 'katha_management.db';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbDirectory = await getDatabasesPath();
    final path = join(dbDirectory, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Enforce FK constraints (off by default on sqflite).
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSalesTables(db);
    // Future modules add their CREATE TABLE calls here, e.g.:
    // await _createPartyTable(db);
    // await _createProductTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example of how future schema changes should be layered in:
    //
    // if (oldVersion < 2) {
    //   await _createPartyTable(db);
    // }
    // if (oldVersion < 3) {
    //   await db.execute('ALTER TABLE sales ADD COLUMN orderId TEXT');
    // }
  }

  Future<void> _createSalesTables(Database db) async {
    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        partyId TEXT,
        partyName TEXT NOT NULL,
        partyPhone TEXT,
        saleDate TEXT NOT NULL,
        totalAmount REAL NOT NULL DEFAULT 0,
        paidAmount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        note TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        saleId TEXT NOT NULL,
        productId TEXT,
        productName TEXT NOT NULL,
        quantity REAL NOT NULL,
        unitPrice REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_sale_items_saleId ON sale_items (saleId)');
    await db.execute('CREATE INDEX idx_sales_partyId ON sales (partyId)');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}