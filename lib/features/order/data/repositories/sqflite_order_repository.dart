// lib/features/order/data/repositories/sqflite_order_repository.dart

import 'package:katha_management/core/models/new_order/new_order_item_model.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import 'order_repository.dart';

/// sqflite-backed implementation of [OrderRepository].
///
/// `orders` and `order_items` are written together inside a single
/// `db.transaction` so an order is never left half-saved if something
/// fails mid-way.
class SqfliteOrderRepository implements OrderRepository {
  SqfliteOrderRepository({AppDatabase? database})
    : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _ordersTable = 'orders';
  static const String _itemsTable = 'order_items';

  @override
  Future<void> createOrder(OrderModel order) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      await txn.insert(
        _ordersTable,
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final item in order.items) {
        await txn.insert(
          _itemsTable,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<List<OrderModel>> getAllOrders() async {
    final db = await _appDatabase.database;
    final rows = await db.query(_ordersTable, orderBy: 'orderDate DESC');
    return _hydrateOrders(db, rows);
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(_ordersTable, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final items = await _itemsForOrder(db, id);
    return OrderModel.fromMap(rows.first, items: items);
  }

  @override
  Future<List<OrderModel>> getOrdersByParty(String partyId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      _ordersTable,
      where: 'partyId = ?',
      whereArgs: [partyId],
      orderBy: 'orderDate DESC',
    );
    return _hydrateOrders(db, rows);
  }

  @override
  Future<List<OrderModel>> getOrdersByStatus(OrderStatus status) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      _ordersTable,
      where: 'status = ?',
      whereArgs: [status.value],
      orderBy: 'orderDate DESC',
    );
    return _hydrateOrders(db, rows);
  }

  @override
  Future<void> updateOrder(OrderModel order) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      await txn.update(
        _ordersTable,
        order.toMap(),
        where: 'id = ?',
        whereArgs: [order.id],
      );

      // Simplest correct approach: replace all items for this order.
      await txn.delete(
        _itemsTable,
        where: 'orderId = ?',
        whereArgs: [order.id],
      );
      for (final item in order.items) {
        await txn.insert(_itemsTable, item.toMap());
      }
    });
  }

  @override
  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    final db = await _appDatabase.database;

    await db.update(
      _ordersTable,
      {'status': status.value, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteOrder(String id) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      await txn.delete(_itemsTable, where: 'orderId = ?', whereArgs: [id]);
      await txn.delete(_ordersTable, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<OrderModel>> _hydrateOrders(
    DatabaseExecutor db,
    List<Map<String, dynamic>> orderRows,
  ) async {
    final orders = <OrderModel>[];
    for (final row in orderRows) {
      final items = await _itemsForOrder(db, row['id'] as String);
      orders.add(OrderModel.fromMap(row, items: items));
    }
    return orders;
  }

  Future<List<OrderItemModel>> _itemsForOrder(
    DatabaseExecutor db,
    String orderId,
  ) async {
    final rows = await db.query(
      _itemsTable,
      where: 'orderId = ?',
      whereArgs: [orderId],
    );
    return rows.map(OrderItemModel.fromMap).toList();
  }
}
