// lib/ui/orders/order_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/features/order/data/repositories/sqflite_order_repository.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/payment/data/repositories/sqflite_payment_repository.dart';

/// ViewModel driving the Orders screen.
///
/// Categorizes orders into Pending (placed, delivered)
/// and Done (paid, cancelled), and allows advancing lifecycle
/// status (placed -> delivered -> paid), collecting advance payments, or cancelling orders.
class OrderViewModel extends ChangeNotifier {
  OrderViewModel({
    OrderRepository? orderRepository,
    PaymentRepository? paymentRepository,
  }) : _orderRepository = orderRepository ?? SqfliteOrderRepository(),
       _paymentRepository = paymentRepository ?? SqflitePaymentRepository() {
    loadOrders();
  }

  final OrderRepository _orderRepository;
  final PaymentRepository _paymentRepository;

  List<OrderModel> _allOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<OrderModel> get allOrders => _allOrders;

  List<OrderModel> get pendingOrders {
    final filtered = _allOrders.where((order) {
      return order.status == OrderStatus.placed ||
          order.status == OrderStatus.delivered;
    }).toList();

    return _applySearch(filtered);
  }

  List<OrderModel> get doneOrders {
    final filtered = _allOrders.where((order) {
      return order.status == OrderStatus.paid ||
          order.status == OrderStatus.cancelled;
    }).toList();

    return _applySearch(filtered);
  }

  int get pendingCount => _allOrders.where((order) {
    return order.status == OrderStatus.placed ||
        order.status == OrderStatus.delivered;
  }).length;

  int get doneCount => _allOrders.where((order) {
    return order.status == OrderStatus.paid ||
        order.status == OrderStatus.cancelled;
  }).length;

  List<OrderModel> _applySearch(List<OrderModel> source) {
    if (_searchQuery.trim().isEmpty) return source;
    final query = _searchQuery.trim().toLowerCase();

    return source.where((order) {
      final nameMatches = order.partyName.toLowerCase().contains(query);
      final phoneMatches =
          order.partyPhone?.toLowerCase().contains(query) ?? false;
      final itemMatches = order.items.any(
        (item) => item.productName.toLowerCase().contains(query),
      );
      final noteMatches = order.note?.toLowerCase().contains(query) ?? false;
      return nameMatches || phoneMatches || itemMatches || noteMatches;
    }).toList();
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allOrders = await _orderRepository.getAllOrders();
      _allOrders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      _errorMessage = 'Failed to load orders: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> refresh() => loadOrders();

  /// Advances the order to its next logical status (placed -> delivered -> paid).
  Future<bool> advanceStatus(OrderModel order) async {
    final nextStatus = order.status.next;
    if (nextStatus == null) return false;

    return updateOrderStatus(order, nextStatus);
  }

  /// Updates the order status. When advancing to [OrderStatus.paid], any remaining
  /// unpaid balance is automatically settled and recorded in SQLite payments.
  Future<bool> updateOrderStatus(
    OrderModel order,
    OrderStatus newStatus,
  ) async {
    try {
      if (newStatus == OrderStatus.paid) {
        final unpaidBalance = order.balanceDue;
        if (unpaidBalance > 0) {
          final payment = PaymentModel(
            partyId: order.partyId,
            partyName: order.partyName,
            partyPhone: order.partyPhone,
            amount: unpaidBalance,
            mode: order.paymentMode,
            note:
                'Settled on Order #${order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id} marked as Paid',
          );
          await _paymentRepository.insertPayment(payment);
        }

        final updatedOrder = order.copyWith(
          status: OrderStatus.paid,
          advancePaid: order.totalAmount,
        );
        await _orderRepository.updateOrder(updatedOrder);
      } else {
        await _orderRepository.updateOrderStatus(order.id, newStatus);
      }

      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update order status: $e';
      notifyListeners();
      return false;
    }
  }

  /// Cancels an order.
  Future<bool> cancelOrder(String orderId) async {
    try {
      await _orderRepository.updateOrderStatus(orderId, OrderStatus.cancelled);
      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel order: $e';
      notifyListeners();
      return false;
    }
  }

  /// Records payment received directly against an order and updates advance balance.
  Future<bool> recordOrderPayment(
    OrderModel order,
    double amount,
    PaymentMode mode,
    String? note,
  ) async {
    if (amount <= 0) return false;

    try {
      final payment = PaymentModel(
        partyId: order.partyId,
        partyName: order.partyName,
        partyPhone: order.partyPhone,
        amount: amount,
        mode: mode,
        note:
            note ??
            'Payment collected on Order #${order.id.substring(0, 6).toUpperCase()}',
      );

      await _paymentRepository.insertPayment(payment);

      final updatedOrder = order.copyWith(
        advancePaid: order.advancePaid + amount,
      );
      await _orderRepository.updateOrder(updatedOrder);

      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to record payment: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deletes an order permanently.
  Future<bool> deleteOrder(String orderId) async {
    try {
      await _orderRepository.deleteOrder(orderId);
      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete order: $e';
      notifyListeners();
      return false;
    }
  }
}
