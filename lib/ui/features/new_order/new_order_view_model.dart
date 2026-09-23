// lib/ui/features/new_order/new_order_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/new_order/new_order_item_model.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/product/product_model.dart';
import 'package:katha_management/core/models/product/product_size_model.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/features/order/data/repositories/sqflite_order_repository.dart';
import 'package:katha_management/features/party/data/repositories/party_repository.dart';
import 'package:katha_management/features/party/data/repositories/sqflite_party_repository.dart';
import 'package:katha_management/features/product/data/repositories/product_repository.dart';
import 'package:katha_management/features/product/data/repositories/sqflite_product_repository.dart';
import 'package:katha_management/ui/features/new_sale/new_sale_view_model.dart';

/// Drives the New Order form with full product catalog, size variant selection,
/// mutable prices for special customers, and strict party linking.
class NewOrderViewModel extends ChangeNotifier {
  NewOrderViewModel({
    String? initialPartyId,
    OrderRepository? repository,
    PartyRepository? partyRepository,
    ProductRepository? productRepository,
  }) : _repository = repository ?? SqfliteOrderRepository(),
       _partyRepository = partyRepository ?? SqflitePartyRepository(),
       _productRepository = productRepository ?? SqfliteProductRepository(),
       selectedPartyId = initialPartyId {
    _init(initialPartyId);
  }

  final OrderRepository _repository;
  final PartyRepository _partyRepository;
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

  // ─── Selected Items Map (Key: '${productId}_${sizeId ?? "base"}') ──
  final Map<String, SelectedProductState> _selectedItems = {};
  Map<String, SelectedProductState> get selectedItems => _selectedItems;

  // Manual custom one-off items
  final List<OrderItemModel> _customItems = [];
  List<OrderItemModel> get customItems => List.unmodifiable(_customItems);

  DateTime? expectedDeliveryDate;
  String? note;

  bool isSaving = false;
  String? errorMessage;

  /// Combines catalog items and custom items into standard OrderItemModels.
  List<OrderItemModel> get items {
    final catalogList = _selectedItems.values.map((item) {
      return OrderItemModel(
        orderId: '',
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

  void setExpectedDeliveryDate(DateTime? date) {
    expectedDeliveryDate = date;
    notifyListeners();
  }

  void setNote(String value) {
    note = value;
    notifyListeners();
  }

  // ─── Product Selection & Mutable Pricing Methods ───────────────────

  static String getItemKey(String productId, String? sizeId) {
    return '${productId}_${sizeId ?? "base"}';
  }

  bool isVariantSelected(String productId, String? sizeId) {
    final key = getItemKey(productId, sizeId);
    return _selectedItems.containsKey(key);
  }

  SelectedProductState? getVariantState(String productId, String? sizeId) {
    final key = getItemKey(productId, sizeId);
    return _selectedItems[key];
  }

  void toggleProductVariant(
    ProductModel product,
    ProductSizeModel? size,
    bool isSelected,
  ) {
    final key = getItemKey(product.id, size?.id);
    if (isSelected) {
      final defaultPrice = size?.finalPrice ?? product.finalPrice;
      _selectedItems[key] = SelectedProductState(
        key: key,
        productId: product.id,
        sizeId: size?.id,
        productName: product.name,
        sizeLabel: size?.label,
        defaultPrice: defaultPrice,
        unitPrice: defaultPrice, // Mutable price starts at default
        quantity: 1.0,
        discount: 0.0,
      );
    } else {
      _selectedItems.remove(key);
    }
    notifyListeners();
  }

  void updateVariantQuantity(String key, double qty) {
    final item = _selectedItems[key];
    if (item != null) {
      if (qty <= 0) {
        _selectedItems.remove(key);
      } else {
        item.quantity = qty;
      }
      notifyListeners();
    }
  }

  void updateVariantPrice(String key, double price) {
    final item = _selectedItems[key];
    if (item != null) {
      item.unitPrice = price >= 0 ? price : 0;
      notifyListeners();
    }
  }

  void updateVariantDiscount(String key, double discount) {
    final item = _selectedItems[key];
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
      OrderItemModel(
        orderId: '',
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

  Future<bool> saveOrder() async {
    if (!canSave) {
      errorMessage = 'Select a party and at least one item before saving.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final orderItems = items;
      final order = OrderModel(
        partyId: selectedPartyId,
        partyName: partyName.trim(),
        partyPhone: partyPhone.trim().isEmpty ? null : partyPhone.trim(),
        expectedDeliveryDate: expectedDeliveryDate,
        items: orderItems,
        status: OrderStatus.placed,
        note: note,
      );

      final finalOrder = order.copyWith(
        items: orderItems.map((item) => item.attachToOrder(order.id)).toList(),
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
    _selectedItems.clear();
    _customItems.clear();
  }
}
