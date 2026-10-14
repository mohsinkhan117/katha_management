// lib/features/product/data/repositories/sqflite_product_repository.dart

import 'package:sqflite/sqflite.dart';

import 'package:katha_management/core/database/app_database.dart';
import 'package:katha_management/core/models/product/product_model.dart';
import 'package:katha_management/core/models/product/product_size_model.dart';
import 'product_repository.dart';

/// sqflite-backed implementation of [ProductRepository].
///
/// `products` and `product_sizes` are written together inside a
/// single `db.transaction` so a product is never left half-saved (its
/// row written but its size variants missing) if something fails
/// mid-way — same pattern as Sale/Order.
class SqfliteProductRepository implements ProductRepository {
  SqfliteProductRepository({AppDatabase? database})
    : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _productsTable = 'products';
  static const String _sizesTable = 'product_sizes';

  @override
  Future<void> createProduct(ProductModel product) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      await txn.insert(
        _productsTable,
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final size in product.sizes) {
        await txn.insert(
          _sizesTable,
          size.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<List<ProductModel>> getAllProducts({
    bool includeInactive = false,
  }) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      _productsTable,
      where: includeInactive ? null : 'isActive = ?',
      whereArgs: includeInactive ? null : [1],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return _hydrateProducts(db, rows);
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      _productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;

    final sizes = await _sizesForProduct(db, id);
    return ProductModel.fromMap(rows.first, sizes: sizes);
  }

  @override
  Future<List<ProductModel>> searchProducts(
    String query, {
    bool includeInactive = false,
  }) async {
    final db = await _appDatabase.database;
    final likeQuery = '%$query%';

    final whereClause = includeInactive
        ? '(name LIKE ? COLLATE NOCASE OR sku LIKE ? COLLATE NOCASE OR category LIKE ? COLLATE NOCASE)'
        : '(name LIKE ? COLLATE NOCASE OR sku LIKE ? COLLATE NOCASE OR category LIKE ? COLLATE NOCASE) AND isActive = 1';

    final rows = await db.query(
      _productsTable,
      where: whereClause,
      whereArgs: [likeQuery, likeQuery, likeQuery],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return _hydrateProducts(db, rows);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      await txn.update(
        _productsTable,
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );

      // Simplest correct approach: replace all size rows for this
      // product, same pattern as Sale/Order line items on update.
      await txn.delete(
        _sizesTable,
        where: 'productId = ?',
        whereArgs: [product.id],
      );
      for (final size in product.sizes) {
        await txn.insert(_sizesTable, size.toMap());
      }
    });
  }

  @override
  Future<void> setActive(String id, bool isActive) async {
    final db = await _appDatabase.database;
    await db.update(
      _productsTable,
      {
        'isActive': isActive ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ProductModel>> _hydrateProducts(
    DatabaseExecutor db,
    List<Map<String, dynamic>> rows,
  ) async {
    final products = <ProductModel>[];
    for (final row in rows) {
      final sizes = await _sizesForProduct(db, row['id'] as String);
      products.add(ProductModel.fromMap(row, sizes: sizes));
    }
    return products;
  }

  Future<List<ProductSizeModel>> _sizesForProduct(
    DatabaseExecutor db,
    String productId,
  ) async {
    final rows = await db.query(
      _sizesTable,
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'sortOrder ASC',
    );
    return rows.map(ProductSizeModel.fromMap).toList();
  }
}
