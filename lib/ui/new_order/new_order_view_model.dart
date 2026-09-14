// lib/features/order/logic/new_order_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/new_order/new_order_item_model.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/features/order/data/repositories/sqflite_order_repository.dart';

/// Drives the New Order form.
///
/// Depends on [OrderRepository] (the interface), not on
/// [SqfliteOrderRepository] directly — a mock repository can be passed
/// in for tests, and a Firestore/sync repository can replace it later
/// without touching this class.
class NewOrderViewModel extends ChangeNotifier {
  NewOrderViewModel({OrderRepository? repository})
    : _repository = repository ?? SqfliteOrderRepository();

  final OrderRepository _repository;

  // ─── Party (manual entry for now — swap for a Party picker once the
  // Party module/Phase 1 exists; nothing else here needs to change) ──
  String? selectedPartyId;
  String partyName = '';
  String partyPhone = '';

  DateTime? expectedDeliveryDate;
  String? note;

  // ─── Line items ────────────────────────────────────────────────────
  final List<OrderItemModel> _items = [];
  List<OrderItemModel> get items => List.unmodifiable(_items);

  bool isSaving = false;
  String? errorMessage;

  double get totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);
  bool get canSave => partyName.trim().isNotEmpty && _items.isNotEmpty;

  void setParty({String? id, required String name, String? phone}) {
    selectedPartyId = id;
    partyName = name;
    partyPhone = phone ?? '';
    notifyListeners();
  }

  void setExpectedDeliveryDate(DateTime? date) {
    expectedDeliveryDate = date;
    notifyListeners();
  }

  void setNote(String value) {
    note = value;
    notifyListeners();
  }

  void addItem({
    required String productName,
    required double quantity,
    required double unitPrice,
    double discount = 0,
    String? productId,
  }) {
    _items.add(
      OrderItemModel(
        orderId: '', // linked to the real order id in saveOrder()
        productId: productId,
        productName: productName,
        quantity: quantity,
        unitPrice: unitPrice,
        discount: discount,
      ),
    );
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  Future<bool> saveOrder() async {
    if (!canSave) {
      errorMessage = 'Add a party and at least one item before saving.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final order = OrderModel(
        partyId: selectedPartyId,
        partyName: partyName.trim(),
        partyPhone: partyPhone.trim(),
        expectedDeliveryDate: expectedDeliveryDate,
        items: _items,
        status: OrderStatus.placed,
        note: note,
      );

      // Items were created before the order existed, so re-point them
      // at the order's generated id right before persisting.
      final finalOrder = order.copyWith(
        items: _items.map((item) => item.attachToOrder(order.id)).toList(),
      );

      await _repository.createOrder(finalOrder);
      _resetForm();
      return true;
    } catch (e) {
      errorMessage = 'Failed to save order: $e';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    selectedPartyId = null;
    partyName = '';
    partyPhone = '';
    expectedDeliveryDate = null;
    note = null;
    _items.clear();
  }
}
