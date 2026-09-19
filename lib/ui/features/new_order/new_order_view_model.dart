// lib/ui/features/new_order/new_order_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/new_order/new_order_item_model.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/features/order/data/repositories/sqflite_order_repository.dart';
import 'package:katha_management/features/party/data/repositories/party_repository.dart';
import 'package:katha_management/features/party/data/repositories/sqflite_party_repository.dart';

/// Drives the New Order form with complete party linking.
class NewOrderViewModel extends ChangeNotifier {
  NewOrderViewModel({
    String? initialPartyId,
    OrderRepository? repository,
    PartyRepository? partyRepository,
  }) : _repository = repository ?? SqfliteOrderRepository(),
       _partyRepository = partyRepository ?? SqflitePartyRepository(),
       selectedPartyId = initialPartyId {
    _init(initialPartyId);
  }

  final OrderRepository _repository;
  final PartyRepository _partyRepository;

  // ─── Party details ─────────────────────────────────────────────────
  String? selectedPartyId;
  String partyName = '';
  String partyPhone = '';
  PartyModel? linkedParty;

  List<PartyModel> availableParties = [];
  bool isLoadingParties = false;

  DateTime? expectedDeliveryDate;
  String? note;

  // ─── Line items ────────────────────────────────────────────────────
  final List<OrderItemModel> _items = [];
  List<OrderItemModel> get items => List.unmodifiable(_items);

  bool isSaving = false;
  String? errorMessage;

  double get totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);
  bool get canSave => partyName.trim().isNotEmpty && _items.isNotEmpty;

  Future<void> _init(String? partyId) async {
    isLoadingParties = true;
    notifyListeners();

    try {
      availableParties = await _partyRepository.getAllParties();

      if (partyId != null) {
        final party = await _partyRepository.getPartyById(partyId);
        if (party != null) {
          selectParty(party);
        }
      }
    } catch (_) {
      // Fallback
    } finally {
      isLoadingParties = false;
      notifyListeners();
    }
  }

  void selectParty(PartyModel party) {
    selectedPartyId = party.id;
    linkedParty = party;
    partyName = party.name;
    partyPhone = party.phone ?? '';
    notifyListeners();
  }

  void clearSelectedParty() {
    selectedPartyId = null;
    linkedParty = null;
    partyName = '';
    partyPhone = '';
    notifyListeners();
  }

  void setPartyManual({required String name, String? phone}) {
    selectedPartyId = null;
    linkedParty = null;
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
        orderId: '', // linked to real order id in saveOrder()
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
        partyPhone: partyPhone.trim().isEmpty ? null : partyPhone.trim(),
        expectedDeliveryDate: expectedDeliveryDate,
        items: _items,
        status: OrderStatus.placed,
        note: note,
      );

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
    linkedParty = null;
    partyName = '';
    partyPhone = '';
    expectedDeliveryDate = null;
    note = null;
    _items.clear();
  }
}
