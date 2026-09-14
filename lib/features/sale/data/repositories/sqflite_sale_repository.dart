// lib/features/sale/data/repositories/sqflite_sale_repository.dart

import 'package:katha_management/core/models/sale_item_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import 'sale_repository.dart';

/// sqflite-backed implementation of [SaleRepository].
///
/// `sales` and `sale_items` are written together inside a single
/// `db.transaction` so a sale is never left half-saved (e.g. header
/// row written but items missing) if something fails mid-way.
class SqfliteSaleRepository implements SaleRepository {
  SqfliteSaleRepository({AppDatabase? database})
    : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _salesTable = 'sales';
  static const String _itemsTable = 'sale_items';

  @override
  Future<void> createSale(SaleModel sale) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      await txn.insert(
        _salesTable,
        sale.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final item in sale.items) {
        await txn.insert(
          _itemsTable,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<List<SaleModel>> getAllSales() async {
    final db = await _appDatabase.database;
    final rows = await db.query(_salesTable, orderBy: 'saleDate DESC');
    return _hydrateSales(db, rows);
  }

  @override
  Future<SaleModel?> getSaleById(String id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(_salesTable, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final items = await _itemsForSale(db, id);
    return SaleModel.fromMap(rows.first, items: items);
  }

  @override
  Future<List<SaleModel>> getSalesByParty(String partyId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      _salesTable,
      where: 'partyId = ?',
      whereArgs: [partyId],
      orderBy: 'saleDate DESC',
    );
    return _hydrateSales(db, rows);
  }

  @override
  Future<void> updateSale(SaleModel sale) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      await txn.update(
        _salesTable,
        sale.toMap(),
        where: 'id = ?',
        whereArgs: [sale.id],
      );

      // Simplest correct approach: replace all items for this sale.
      await txn.delete(_itemsTable, where: 'saleId = ?', whereArgs: [sale.id]);
      for (final item in sale.items) {
        await txn.insert(_itemsTable, item.toMap());
      }
    });
  }

  @override
  Future<void> deleteSale(String id) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      // Explicit delete kept even though the FK has ON DELETE CASCADE,
      // since sqflite only enforces that when foreign_keys is ON
      // (set in AppDatabase.onConfigure) — this keeps behavior correct
      // even if that pragma is ever removed.
      await txn.delete(_itemsTable, where: 'saleId = ?', whereArgs: [id]);
      await txn.delete(_salesTable, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<SaleModel>> _hydrateSales(
    DatabaseExecutor db,
    List<Map<String, dynamic>> saleRows,
  ) async {
    final sales = <SaleModel>[];
    for (final row in saleRows) {
      final items = await _itemsForSale(db, row['id'] as String);
      sales.add(SaleModel.fromMap(row, items: items));
    }
    return sales;
  }

  Future<List<SaleItemModel>> _itemsForSale(
    DatabaseExecutor db,
    String saleId,
  ) async {
    final rows = await db.query(
      _itemsTable,
      where: 'saleId = ?',
      whereArgs: [saleId],
    );
    return rows.map(SaleItemModel.fromMap).toList();
  }
}
