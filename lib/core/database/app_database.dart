// lib/core/database/app_database.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  static Database? _database;

  // Version 2:
  // Added products and product_sizes tables.
  static const int _dbVersion = 2;

  static const String _dbName = 'katha_management.db';

  // Returns the single database instance.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Opens or creates the database.
  Future<Database> _initDatabase() async {
    final dbDirectory = await getDatabasesPath();
    final path = join(dbDirectory, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Enable foreign key constraints.
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Runs when the database is created for the first time.
  Future<void> _onCreate(Database db, int version) async {
    await _createPartiesTable(db);
    await _createSalesTables(db);
    await _createOrdersTables(db);
    await _createPaymentsTables(db);
    await _createProductsTables(db);
  }

  // Runs when an existing database is upgraded.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // ------------------------------------------------------------
    // Version 1 → Version 2
    // ------------------------------------------------------------
    if (oldVersion < 2) {
      // Add the product catalog.
      await _createProductsTables(db);
    }

    // ------------------------------------------------------------
    // Future Version 2 → Version 3
    // ------------------------------------------------------------
    /*
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE parties '
        'ADD COLUMN creditLimit REAL NOT NULL DEFAULT 0',
      );
    }
    */
  }

  // ------------------------------------------------------------
  // Parties
  // ------------------------------------------------------------

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

    await db.execute(
      'CREATE INDEX idx_parties_name '
      'ON parties (name)',
    );
  }

  // ------------------------------------------------------------
  // Sales
  // ------------------------------------------------------------

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

        FOREIGN KEY (saleId)
          REFERENCES sales (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_sale_items_saleId '
      'ON sale_items (saleId)',
    );

    await db.execute(
      'CREATE INDEX idx_sales_partyId '
      'ON sales (partyId)',
    );
  }

  // ------------------------------------------------------------
  // Orders
  // ------------------------------------------------------------

  Future<void> _createOrdersTables(Database db) async {
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        convertedSaleId TEXT,
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

        FOREIGN KEY (orderId)
          REFERENCES orders (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_order_items_orderId '
      'ON order_items (orderId)',
    );

    await db.execute(
      'CREATE INDEX idx_orders_partyId '
      'ON orders (partyId)',
    );

    await db.execute(
      'CREATE INDEX idx_orders_status '
      'ON orders (status)',
    );
  }

  // ------------------------------------------------------------
  // Payments
  // ------------------------------------------------------------

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

    await db.execute('''
      CREATE TABLE payment_allocations (
        id TEXT PRIMARY KEY,
        paymentId TEXT NOT NULL,
        saleId TEXT NOT NULL,
        amountApplied REAL NOT NULL,

        FOREIGN KEY (paymentId)
          REFERENCES payments (id)
          ON DELETE CASCADE,

        FOREIGN KEY (saleId)
          REFERENCES sales (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_payments_partyId '
      'ON payments (partyId)',
    );

    await db.execute(
      'CREATE INDEX idx_payment_allocations_paymentId '
      'ON payment_allocations (paymentId)',
    );

    await db.execute(
      'CREATE INDEX idx_payment_allocations_saleId '
      'ON payment_allocations (saleId)',
    );
  }

  // ------------------------------------------------------------
  // Products
  // Version 2
  // ------------------------------------------------------------

  Future<void> _createProductsTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,

        name TEXT NOT NULL,
        description TEXT,
        imageUrl TEXT,

        sku TEXT,
        category TEXT,
        unit TEXT,

        retailPrice REAL NOT NULL DEFAULT 0,
        discountPrice REAL,
        costPrice REAL,

        stockQuantity INTEGER NOT NULL DEFAULT 0,

        status TEXT NOT NULL DEFAULT 'inStock',
        isActive INTEGER NOT NULL DEFAULT 1,

        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,

        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Different sizes / variants of a product.
    //
    // Example:
    // Product = Cooking Oil
    //
    // Sizes:
    // 1 Liter  -> Rs. 550
    // 3 Liter  -> Rs. 1550
    // 5 Liter  -> Rs. 2500
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_sizes (
        id TEXT PRIMARY KEY,

        productId TEXT NOT NULL,

        label TEXT NOT NULL,

        price REAL NOT NULL,
        discountPrice REAL,

        sortOrder INTEGER NOT NULL DEFAULT 0,

        FOREIGN KEY (productId)
          REFERENCES products (id)
          ON DELETE CASCADE
      )
    ''');

    // ------------------------------------------------------------
    // Product Indexes
    // ------------------------------------------------------------

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_name '
      'ON products (name)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_category '
      'ON products (category)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_sku '
      'ON products (sku)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_status '
      'ON products (status)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_product_sizes_productId '
      'ON product_sizes (productId)',
    );
  }

  // ------------------------------------------------------------
  // Close Database
  // ------------------------------------------------------------

  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
