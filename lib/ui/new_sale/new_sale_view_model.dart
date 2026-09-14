// lib\core\ui\new_sale\new_sale_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/sale_item_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:katha_management/features/sale/data/repositories/sale_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sqflite_sale_repository.dart';

/// Drives the New Sale form.
///
/// Depends on [SaleRepository] (the interface), not on
/// [SqfliteSaleRepository] directly — a mock repository can be passed
/// in for tests, and a Firestore/sync repository can replace it later
/// without touching this class.
class NewSaleViewModel extends ChangeNotifier {
  NewSaleViewModel({SaleRepository? repository})
    : _repository = repository ?? SqfliteSaleRepository();

  final SaleRepository _repository;

  // ─── Party (manual entry for now — swap for a Party picker once the
  // Party module/Phase 1 exists; nothing else here needs to change) ──
  String? selectedPartyId;
  String partyName = '';
  String partyPhone = '';

  // ─── Line items ────────────────────────────────────────────────────
  final List<SaleItemModel> _items = [];
  List<SaleItemModel> get items => List.unmodifiable(_items);

  double paidAmount = 0;
  String? note;

  bool isSaving = false;
  String? errorMessage;

  double get totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get balanceDue => totalAmount - paidAmount;
  bool get canSave => partyName.trim().isNotEmpty && _items.isNotEmpty;

  void setParty({String? id, required String name, String? phone}) {
    selectedPartyId = id;
    partyName = name;
    partyPhone = phone ?? '';
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
      SaleItemModel(
        saleId: '', // linked to the real sale id in saveSale()
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

  void setPaidAmount(double amount) {
    paidAmount = amount;
    notifyListeners();
  }

  void setNote(String value) {
    note = value;
    notifyListeners();
  }

  Future<bool> saveSale() async {
    if (!canSave) {
      errorMessage = 'Add a party and at least one item before saving.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final sale = SaleModel(
        partyId: selectedPartyId,
        partyName: partyName.trim(),
        partyPhone: partyPhone.trim(),
        items: _items,
        paidAmount: paidAmount,
        note: note,
      );

      // Items were created before the sale existed, so re-point them
      // at the sale's generated id right before persisting.
      final finalSale = sale.copyWith(
        items: _items.map((item) => item.attachToSale(sale.id)).toList(),
      );

      await _repository.createSale(finalSale);
      _resetForm();
      return true;
    } catch (e) {
      errorMessage = 'Failed to save sale: $e';
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
    _items.clear();
    paidAmount = 0;
    note = null;
  }
}
