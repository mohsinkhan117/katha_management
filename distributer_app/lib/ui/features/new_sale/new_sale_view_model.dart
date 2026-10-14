// lib/ui/features/new_sale/new_sale_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/payment/payment_allocation_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/models/product/product_model.dart';
import 'package:katha_management/core/models/product/product_size_model.dart';
import 'package:katha_management/core/models/sale_item_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:katha_management/features/party/data/repositories/party_repository.dart';
import 'package:katha_management/features/party/data/repositories/sqflite_party_repository.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/payment/data/repositories/sqflite_payment_repository.dart';
import 'package:katha_management/features/product/data/repositories/product_repository.dart';
import 'package:katha_management/features/product/data/repositories/sqflite_product_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sale_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sqflite_sale_repository.dart';

/// Represents the selection and mutable pricing state of a product.
class SelectedProductState {
  final String key;
  final String productId;
  final String? sizeId;
  final String productName;
  final String? sizeLabel;
  final double defaultPrice;
  double unitPrice; // mutable price for discounts / custom pricing
  double quantity;
  double discount;

  SelectedProductState({
    required this.key,
    required this.productId,
    this.sizeId,
    required this.productName,
    this.sizeLabel,
    required this.defaultPrice,
    required this.unitPrice,
    this.quantity = 1.0,
    this.discount = 0.0,
  });

  String get displayName =>
      sizeLabel != null ? '$productName ($sizeLabel)' : productName;

  double get subtotal {
    final raw = (quantity * unitPrice) - discount;
    return raw < 0 ? 0 : raw;
  }
}

/// Drives the New Sale form with product catalog selection, size dropdowns,
/// mutable pricing, and strict party linking with payment statistics.
class NewSaleViewModel extends ChangeNotifier {
  NewSaleViewModel({
    String? initialPartyId,
    SaleRepository? repository,
    PartyRepository? partyRepository,
    PaymentRepository? paymentRepository,
    ProductRepository? productRepository,
  }) : _repository = repository ?? SqfliteSaleRepository(),
       _partyRepository = partyRepository ?? SqflitePartyRepository(),
       _paymentRepository = paymentRepository ?? SqflitePaymentRepository(),
       _productRepository = productRepository ?? SqfliteProductRepository(),
       selectedPartyId = initialPartyId {
    _init(initialPartyId);
  }

  final SaleRepository _repository;
  final PartyRepository _partyRepository;
  final PaymentRepository _paymentRepository;
  final ProductRepository _productRepository;

  // ─── Party details ─────────────────────────────────────────────────
  String? selectedPartyId;
  String partyName = '';
  String partyPhone = '';
  PartyModel? linkedParty;

  List<PartyModel> availableParties = [];
  bool isLoadingParties = false;

  // ─── Product Catalog ───────────────────────────────────────────────
  List<ProductModel> availableProducts = [];
  bool isLoadingProducts = false;
  String productSearchQuery = '';

  // ─── Selected Items Map (Key: productId) ───────────────────────────
  final Map<String, SelectedProductState> _selectedItems = {};
  Map<String, SelectedProductState> get selectedItems => _selectedItems;

  // Manual custom one-off items
  final List<SaleItemModel> _customItems = [];
  List<SaleItemModel> get customItems => List.unmodifiable(_customItems);

  double paidAmount = 0;
  PaymentMode paymentMode = PaymentMode.cash;
  String? note;

  bool isSaving = false;
  String? errorMessage;

  /// Combines catalog items and custom items into standard SaleItemModels.
  List<SaleItemModel> get items {
    final catalogList = _selectedItems.values.map((item) {
      return SaleItemModel(
        saleId: '',
        productId: item.productId,
        productName: item.displayName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discount: item.discount,
      );
    }).toList();

    return [...catalogList, ..._customItems];
  }

  double get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);
  double get balanceDue => totalAmount - paidAmount;
  bool get canSave => partyName.trim().isNotEmpty && items.isNotEmpty;

  List<ProductModel> get filteredProducts {
    if (productSearchQuery.trim().isEmpty) return availableProducts;
    final query = productSearchQuery.trim().toLowerCase();
    return availableProducts.where((p) {
      final matchName = p.name.toLowerCase().contains(query);
      final matchCategory = (p.category ?? '').toLowerCase().contains(query);
      final matchSku = (p.sku ?? '').toLowerCase().contains(query);
      return matchName || matchCategory || matchSku;
    }).toList();
  }

  Future<void> _init(String? partyId) async {
    isLoadingParties = true;
    isLoadingProducts = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _partyRepository.getAllParties(),
        _productRepository.getAllProducts(),
      ]);

      availableParties = results[0] as List<PartyModel>;
      availableProducts = results[1] as List<ProductModel>;

      if (partyId != null) {
        final party = await _partyRepository.getPartyById(partyId);
        if (party != null) {
          selectParty(party);
        }
      }
    } catch (_) {
      // Fallback gracefully
    } finally {
      isLoadingParties = false;
      isLoadingProducts = false;
      notifyListeners();
    }
  }

  void setProductSearchQuery(String query) {
    productSearchQuery = query;
    notifyListeners();
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

  // ─── Product Selection & Mutable Pricing Methods ───────────────────

  bool isProductSelected(String productId) {
    return _selectedItems.containsKey(productId);
  }

  SelectedProductState? getProductState(String productId) {
    return _selectedItems[productId];
  }

  /// Toggles product on/off. When checked, defaults to the FIRST available size.
  void toggleProduct(ProductModel product, bool isSelected) {
    if (isSelected) {
      final defaultSize = product.hasSizes ? product.sizes.first : null;
      final defaultPrice = defaultSize?.finalPrice ?? product.finalPrice;

      _selectedItems[product.id] = SelectedProductState(
        key: product.id,
        productId: product.id,
        sizeId: defaultSize?.id,
        productName: product.name,
        sizeLabel: defaultSize?.label,
        defaultPrice: defaultPrice,
        unitPrice: defaultPrice, // Defaults to size's finalPrice, editable
        quantity: 1.0,
        discount: 0.0,
      );
    } else {
      _selectedItems.remove(product.id);
    }
    notifyListeners();
  }

  /// Changes the selected size variant from the dropdown for a product.
  void changeProductSize(ProductModel product, ProductSizeModel newSize) {
    final item = _selectedItems[product.id];
    if (item != null) {
      _selectedItems[product.id] = SelectedProductState(
        key: product.id,
        productId: product.id,
        sizeId: newSize.id,
        productName: product.name,
        sizeLabel: newSize.label,
        defaultPrice: newSize.finalPrice,
        unitPrice: newSize.finalPrice, // Updates price to newly selected size
        quantity: item.quantity,
        discount: item.discount,
      );
      notifyListeners();
    }
  }

  void updateProductQuantity(String productId, double qty) {
    final item = _selectedItems[productId];
    if (item != null) {
      if (qty <= 0) {
        _selectedItems.remove(productId);
      } else {
        item.quantity = qty;
      }
      notifyListeners();
    }
  }

  void updateProductPrice(String productId, double price) {
    final item = _selectedItems[productId];
    if (item != null) {
      item.unitPrice = price >= 0 ? price : 0;
      notifyListeners();
    }
  }

  void updateProductDiscount(String productId, double discount) {
    final item = _selectedItems[productId];
    if (item != null) {
      item.discount = discount >= 0 ? discount : 0;
      notifyListeners();
    }
  }

  void addCustomItem({
    required String productName,
    required double quantity,
    required double unitPrice,
    double discount = 0,
  }) {
    _customItems.add(
      SaleItemModel(
        saleId: '',
        productId: null,
        productName: productName,
        quantity: quantity,
        unitPrice: unitPrice,
        discount: discount,
      ),
    );
    notifyListeners();
  }

  void removeCustomItem(int index) {
    _customItems.removeAt(index);
    notifyListeners();
  }

  void setPaidAmount(double amount) {
    paidAmount = amount;
    notifyListeners();
  }

  void setPaymentMode(PaymentMode mode) {
    paymentMode = mode;
    notifyListeners();
  }

  void setNote(String value) {
    note = value;
    notifyListeners();
  }

  Future<bool> saveSale() async {
    if (!canSave) {
      errorMessage = 'Select a party and at least one item before saving.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      String? effectivePartyId = selectedPartyId;
      final cleanPartyName = partyName.trim();
      final cleanPartyPhone = partyPhone.trim().isEmpty
          ? null
          : partyPhone.trim();

      // Auto-create party if entered on-the-fly and not already existing
      if (effectivePartyId == null && cleanPartyName.isNotEmpty) {
        final existingParties = await _partyRepository.searchParties(
          cleanPartyName,
        );
        final exactMatch = existingParties
            .where(
              (p) =>
                  p.name.trim().toLowerCase() == cleanPartyName.toLowerCase(),
            )
            .firstOrNull;

        if (exactMatch != null) {
          effectivePartyId = exactMatch.id;
        } else {
          final newParty = PartyModel(
            name: cleanPartyName,
            phone: cleanPartyPhone,
          );
          await _partyRepository.createParty(newParty);
          effectivePartyId = newParty.id;
        }
      }

      final saleItems = items;
      final sale = SaleModel(
        partyId: effectivePartyId,
        partyName: cleanPartyName,
        partyPhone: cleanPartyPhone,
        items: saleItems,
        paidAmount: 0,
        note: note,
      );

      final finalSale = sale.copyWith(
        items: saleItems.map((item) => item.attachToSale(sale.id)).toList(),
      );

      // 1. Insert the Sale into SQLite
      await _repository.createSale(finalSale);

      // 2. If upfront payment was made, record payment and allocate
      if (paidAmount > 0) {
        final payment = PaymentModel(
          partyId: effectivePartyId,
          partyName: cleanPartyName,
          partyPhone: cleanPartyPhone,
          amount: paidAmount,
          mode: paymentMode,
          note: note != null && note!.trim().isNotEmpty
              ? note!.trim()
              : 'Paid upfront on Sale',
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
    _selectedItems.clear();
    _customItems.clear();
    paidAmount = 0;
    paymentMode = PaymentMode.cash;
    note = null;
  }
}
