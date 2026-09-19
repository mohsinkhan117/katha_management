// lib/ui/orders/order_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/sale_item_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/features/order/data/repositories/sqflite_order_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sale_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sqflite_sale_repository.dart';

/// ViewModel driving the Orders screen.
///
/// Categorizes orders into Pending (placed, confirmed, dispatched)
/// and Done (delivered, cancelled), and allows advancing lifecycle status,
/// searching, cancelling, or converting delivered orders into sales.
class OrderViewModel extends ChangeNotifier {
  OrderViewModel({
    OrderRepository? orderRepository,
    SaleRepository? saleRepository,
  }) : _orderRepository = orderRepository ?? SqfliteOrderRepository(),
       _saleRepository = saleRepository ?? SqfliteSaleRepository() {
    loadOrders();
  }

  final OrderRepository _orderRepository;
  final SaleRepository _saleRepository;

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

  /// Advances the order to its next logical status (e.g. placed -> confirmed -> dispatched -> delivered).
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

  /// Converts an order into a Sale/Invoice.
  Future<bool> convertToSale(OrderModel order) async {
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
        note:
            'Converted from Order #${order.id.substring(0, 6).toUpperCase()}${order.note != null ? ' - ${order.note}' : ''}',
      );

      final finalSale = sale.copyWith(
        items: saleItems.map((i) => i.attachToSale(sale.id)).toList(),
      );

      await _saleRepository.createSale(finalSale);
      await _orderRepository.updateOrderStatus(order.id, OrderStatus.delivered);
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
