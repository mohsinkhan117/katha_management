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
    await _createPartiesTable(db);
    await _createSalesTables(db);
    await _createOrdersTables(db);
    await _createPaymentsTables(db);
    // Future modules add their CREATE TABLE calls here, e.g.:
    // await _createProductTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example of how future schema changes should be layered in:
    //
    // if (oldVersion < 2) {
    //   await _createProductTable(db);
    // }
    // if (oldVersion < 3) {
    //   await db.execute('ALTER TABLE sales ADD COLUMN orderId TEXT');
    // }
  }

  Future<void> _createPartiesTable(Database db) async {
    await db.execute('''
      CREATE TABLE parties (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        openingBalance REAL NOT NULL DEFAULT 0,
        tag TEXT,
        note TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_parties_name ON parties (name)');
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

    await db.execute(
      'CREATE INDEX idx_sale_items_saleId ON sale_items (saleId)',
    );
    await db.execute('CREATE INDEX idx_sales_partyId ON sales (partyId)');
  }

  Future<void> _createOrdersTables(Database db) async {
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        partyId TEXT,
        partyName TEXT NOT NULL,
        partyPhone TEXT,
        orderDate TEXT NOT NULL,
        expectedDeliveryDate TEXT,
        totalAmount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'placed',
        note TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        orderId TEXT NOT NULL,
        productId TEXT,
        productName TEXT NOT NULL,
        quantity REAL NOT NULL,
        unitPrice REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (orderId) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_order_items_orderId ON order_items (orderId)',
    );
    await db.execute('CREATE INDEX idx_orders_partyId ON orders (partyId)');
    await db.execute('CREATE INDEX idx_orders_status ON orders (status)');
  }

  Future<void> _createPaymentsTables(Database db) async {
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        partyId TEXT,
        partyName TEXT NOT NULL,
        partyPhone TEXT,
        amount REAL NOT NULL,
        paymentDate TEXT NOT NULL,
        mode TEXT NOT NULL DEFAULT 'cash',
        note TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Links a payment to the sale(s) it settles, in whole or in part.
    // A payment with zero rows here is a pure on-account advance.
    await db.execute('''
      CREATE TABLE payment_allocations (
        id TEXT PRIMARY KEY,
        paymentId TEXT NOT NULL,
        saleId TEXT NOT NULL,
        amountApplied REAL NOT NULL,
        FOREIGN KEY (paymentId) REFERENCES payments (id) ON DELETE CASCADE,
        FOREIGN KEY (saleId) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_payments_partyId ON payments (partyId)');
    await db.execute(
      'CREATE INDEX idx_payment_allocations_paymentId ON payment_allocations (paymentId)',
    );
    await db.execute(
      'CREATE INDEX idx_payment_allocations_saleId ON payment_allocations (saleId)',
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
