// lib/features/order/data/repositories/order_repository.dart

import 'package:katha_management/core/models/new_order/new_order_model.dart';

/// Contract for anything that can persist/read orders.
///
/// The ViewModel and View depend only on this interface — never on
/// `SqfliteOrderRepository` directly — so a `FirestoreOrderRepository`
/// or sync-aware repository can replace it in Phase 5 without any
/// change above this layer.
abstract class OrderRepository {
  Future<void> createOrder(OrderModel order);

  Future<List<OrderModel>> getAllOrders();

  Future<OrderModel?> getOrderById(String id);

  Future<List<OrderModel>> getOrdersByParty(String partyId);

  Future<List<OrderModel>> getOrdersByStatus(OrderStatus status);

  Future<void> updateOrder(OrderModel order);

  /// Fast path for moving an order through its status flow without
  /// rewriting every field (and without touching order_items).
  Future<void> updateOrderStatus(String id, OrderStatus status);

  Future<void> deleteOrder(String id);
}
