// lib/ui/orders/order_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/payment/payment_allocation_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/models/sale_item_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/features/order/data/repositories/sqflite_order_repository.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/payment/data/repositories/sqflite_payment_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sale_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sqflite_sale_repository.dart';

/// ViewModel driving the Orders screen.
///
/// Categorizes orders into Pending (placed, confirmed, dispatched)
/// and Done (delivered, cancelled), and allows advancing lifecycle
/// status, collecting payments, cancelling, or converting delivered orders into
/// sales.
class OrderViewModel extends ChangeNotifier {
  OrderViewModel({
    OrderRepository? orderRepository,
    SaleRepository? saleRepository,
    PaymentRepository? paymentRepository,
  }) : _orderRepository = orderRepository ?? SqfliteOrderRepository(),
       _saleRepository = saleRepository ?? SqfliteSaleRepository(),
       _paymentRepository = paymentRepository ?? SqflitePaymentRepository() {
    loadOrders();
  }

  final OrderRepository _orderRepository;
  final SaleRepository _saleRepository;
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
          order.status == OrderStatus.confirmed ||
          order.status == OrderStatus.dispatched;
    }).toList();

    return _applySearch(filtered);
  }

  List<OrderModel> get doneOrders {
    final filtered = _allOrders.where((order) {
      return order.status == OrderStatus.delivered ||
          order.status == OrderStatus.cancelled;
    }).toList();

    return _applySearch(filtered);
  }

  int get pendingCount => _allOrders.where((order) {
    return order.status == OrderStatus.placed ||
        order.status == OrderStatus.confirmed ||
        order.status == OrderStatus.dispatched;
  }).length;

  int get doneCount => _allOrders.where((order) {
    return order.status == OrderStatus.delivered ||
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

  /// Advances the order to its next logical status (placed -> confirmed
  /// -> dispatched -> delivered).
  Future<bool> advanceStatus(OrderModel order) async {
    final nextStatus = order.status.next;
    if (nextStatus == null) return false;

    try {
      await _orderRepository.updateOrderStatus(order.id, nextStatus);
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

  /// Converts an order into a Sale/Invoice.
  ///
  /// Guarded by `order.convertedSaleId`: once an order has produced a
  /// sale, this returns `false` immediately rather than creating a
  /// second one. This check lives here — not just as a hidden button
  /// in the View — because a UI-only guard doesn't protect against a
  /// fast double-tap landing before the first call's rebuild disables
  /// it, or against some future second entry point calling this
  /// method directly.
  Future<bool> convertToSale(OrderModel order) async {
    if (order.convertedSaleId != null) {
      _errorMessage = 'This order has already been converted to a sale.';
      notifyListeners();
      return false;
    }

    try {
      final saleItems = order.items.map((item) {
        return SaleItemModel(
          saleId: '',
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          discount: item.discount,
        );
      }).toList();

      final sale = SaleModel(
        partyId: order.partyId,
        partyName: order.partyName,
        partyPhone: order.partyPhone,
        items: saleItems,
        paidAmount: order.advancePaid,
        note:
            'Converted from Order #${order.id.substring(0, 6).toUpperCase()}${order.note != null ? ' - ${order.note}' : ''}',
      );

      final finalSale = sale.copyWith(
        items: saleItems.map((i) => i.attachToSale(sale.id)).toList(),
      );

      await _saleRepository.createSale(finalSale);

      // If there was an advance payment on the order, allocate it to the generated sale
      if (order.advancePaid > 0) {
        final payment = PaymentModel(
          partyId: order.partyId,
          partyName: order.partyName,
          partyPhone: order.partyPhone,
          amount: order.advancePaid,
          mode: order.paymentMode,
          note: 'Advance on Order #${order.id.substring(0, 6).toUpperCase()}',
        );

        final allocation = PaymentAllocationModel(
          paymentId: payment.id,
          saleId: finalSale.id,
          amountApplied: order.advancePaid > finalSale.totalAmount
              ? finalSale.totalAmount
              : order.advancePaid,
        );

        await _paymentRepository.insertPayment(
          payment,
          allocations: [allocation],
        );
      }

      // Status and the conversion link are written together in one
      // update — if these were two separate repository calls, a
      // failure between them could leave an order marked "delivered"
      // with no record of which sale it produced, or vice versa.
      final updatedOrder = order.copyWith(
        status: OrderStatus.delivered,
        convertedSaleId: finalSale.id,
      );
      await _orderRepository.updateOrder(updatedOrder);

      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to convert order to sale: $e';
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
