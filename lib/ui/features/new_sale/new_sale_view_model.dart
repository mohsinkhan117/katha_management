// lib/ui/features/new_sale/new_sale_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/payment/payment_allocation_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/models/sale_item_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:katha_management/features/party/data/repositories/party_repository.dart';
import 'package:katha_management/features/party/data/repositories/sqflite_party_repository.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/payment/data/repositories/sqflite_payment_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sale_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sqflite_sale_repository.dart';

/// Drives the New Sale form with full party linking and database sync.
class NewSaleViewModel extends ChangeNotifier {
  NewSaleViewModel({
    String? initialPartyId,
    SaleRepository? repository,
    PartyRepository? partyRepository,
    PaymentRepository? paymentRepository,
  }) : _repository = repository ?? SqfliteSaleRepository(),
       _partyRepository = partyRepository ?? SqflitePartyRepository(),
       _paymentRepository = paymentRepository ?? SqflitePaymentRepository(),
       selectedPartyId = initialPartyId {
    _init(initialPartyId);
  }

  final SaleRepository _repository;
  final PartyRepository _partyRepository;
  final PaymentRepository _paymentRepository;

  // ─── Party details ─────────────────────────────────────────────────
  String? selectedPartyId;
  String partyName = '';
  String partyPhone = '';
  PartyModel? linkedParty;

  List<PartyModel> availableParties = [];
  bool isLoadingParties = false;

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
      // Non-critical fallback
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

  void addItem({
    required String productName,
    required double quantity,
    required double unitPrice,
    double discount = 0,
    String? productId,
  }) {
    _items.add(
      SaleItemModel(
        saleId: '', // linked to real sale id in saveSale()
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
        partyPhone: partyPhone.trim().isEmpty ? null : partyPhone.trim(),
        items: _items,
        paidAmount:
            0, // initially 0 so payment allocation updates it accurately
        note: note,
      );

      final finalSale = sale.copyWith(
        items: _items.map((item) => item.attachToSale(sale.id)).toList(),
      );

      // 1. Insert the Sale
      await _repository.createSale(finalSale);

      // 2. If an upfront payment was made, record payment and allocation
      if (paidAmount > 0) {
        final payment = PaymentModel(
          partyId: selectedPartyId,
          partyName: partyName.trim(),
          partyPhone: partyPhone.trim().isEmpty ? null : partyPhone.trim(),
          amount: paidAmount,
          note: 'Paid upfront on Sale',
        );

        final allocation = PaymentAllocationModel(
          paymentId: payment.id,
          saleId: finalSale.id,
          amountApplied: paidAmount > totalAmount ? totalAmount : paidAmount,
        );

        await _paymentRepository.insertPayment(
          payment,
          allocations: [allocation],
        );
      }

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
    linkedParty = null;
    partyName = '';
    partyPhone = '';
    _items.clear();
    paidAmount = 0;
    note = null;
  }
}
