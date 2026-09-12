// lib/core/service/db/order_service.dart

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:katha_management/core/models/order.dart';
import 'package:katha_management/core/models/order_item.dart';
import 'package:katha_management/core/service/db/firestore_paths.dart';

/// CRUD for the `orders` collection.
///
/// ASSUMES `FirestorePaths.orders` exists (e.g. `static const orders =
/// 'orders';`) alongside `menu`/`tables` — add it if it isn't there yet.
class OrderService {
  OrderService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(FirestorePaths.orders);

  /// The single open (status == open) order for [tableId], if any. A table
  /// should never have more than one open order — [createOrder] is only
  /// ever called after confirming none exists (see
  /// `NewOrderViewModel.saveOrder`), so `.limit(1)` is safe here.
  ///
  /// NOTE: this is a compound query (`tableId` == X AND `status` == Y) —
  /// Firestore will require a composite index the first time it runs; it
  /// prints a console link to auto-create one on first failure.
  Stream<Order?> openOrderForTable(String tableId) {
    return _orders
        .where('tableId', isEqualTo: tableId)
        .where('status', isEqualTo: OrderStatus.open.name)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          final doc = snap.docs.first;
          return Order.fromMap(doc.id, doc.data());
        });
  }

  /// Orders that have been finalized (status == submitted) but don't yet
  /// have an [Invoice] — normally a brief in-flight state right after
  /// "Finish & Invoice" is tapped, but also the recovery path if invoice
  /// creation fails after the order was already marked submitted (see
  /// `NewOrderViewModel.finalizeOrder`). Invoice History surfaces these so
  /// staff can generate + print manually instead of the order being lost.
  ///
  /// NOTE: equality-filter + orderBy-on-a-different-field also needs a
  /// composite index — same one-time console-link setup as above.
  Stream<List<Order>> pendingOrders() {
    return _orders
        .where('status', isEqualTo: OrderStatus.submitted.name)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Order.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<String> createOrder(Order order) async {
    final map = order.toMap()..['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _orders.add(map);
    return ref.id;
  }

  Future<void> updateItems(String orderId, List<OrderItem> items) {
    return _orders.doc(orderId).update({
      'items': items.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStatus(String orderId, OrderStatus status) {
    return _orders.doc(orderId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
