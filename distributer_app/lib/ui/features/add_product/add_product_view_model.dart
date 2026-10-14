// lib/ui/features/add_product/add_product_view_model.dart

import 'package:flutter/material.dart';

import 'package:katha_management/core/models/product/product_model.dart';
import 'package:katha_management/core/models/product/product_size_model.dart';
import 'package:katha_management/features/product/data/repositories/product_repository.dart';
import 'package:katha_management/features/product/data/repositories/sqflite_product_repository.dart';

/// Drives the Add/Edit Product form.
///
/// Doubles as both "Add" and "Edit": pass an existing [ProductModel]
/// in and the form pre-fills from it and calls `updateProduct` instead
/// of `createProduct` on save.
class AddProductViewModel extends ChangeNotifier {
  AddProductViewModel({
    ProductRepository? repository,
    ProductModel? existingProduct,
  }) : _repository = repository ?? SqfliteProductRepository(),
       _existingProduct = existingProduct {
    if (existingProduct != null) {
      name = existingProduct.name;
      description = existingProduct.description ?? '';
      imageUrl = existingProduct.imageUrl ?? '';
      sku = existingProduct.sku ?? '';
      category = existingProduct.category ?? '';
      unit = existingProduct.unit ?? '';
      retailPrice = existingProduct.retailPrice;
      discountPercentage = existingProduct.discountPercentage;
      costPrice = existingProduct.costPrice ?? 0;
      stockQuantity = existingProduct.stockQuantity;
      status = existingProduct.status;
      _sizes.addAll(existingProduct.sizes);
    }
  }

  final ProductRepository _repository;
  final ProductModel? _existingProduct;

  bool get isEditing => _existingProduct != null;

  String name = '';
  String description = '';
  String imageUrl = '';
  String sku = '';
  String category = '';
  String unit = '';
  double retailPrice = 0;
  double discountPercentage = 0; // 0-100
  double costPrice = 0;
  int stockQuantity = 0;
  ProductStatus status = ProductStatus.inStock;

  final List<ProductSizeModel> _sizes = [];
  List<ProductSizeModel> get sizes => List.unmodifiable(_sizes);

  bool isSaving = false;
  String? errorMessage;

  bool get canSave => name.trim().isNotEmpty && retailPrice > 0;

  // ─── Live pricing preview — same formula that gets baked into
  // `finalPrice` on save, so what the user sees while typing always
  // matches what actually gets stored. ────────────────────────────
  double get finalPricePreview =>
      ProductModel.calculateFinalPrice(retailPrice, discountPercentage);

  double get discountAmountPreview => retailPrice - finalPricePreview;

  bool get hasDiscountPreview => discountPercentage > 0;

  /// `null` when no cost price has been entered yet — lets the View
  /// show "enter a cost price to see margin" instead of a misleading
  /// zero.
  double? get profitMarginPreview =>
      costPrice > 0 ? finalPricePreview - costPrice : null;

  double? get profitMarginPercentagePreview {
    final margin = profitMarginPreview;
    if (margin == null || finalPricePreview <= 0) return null;
    return (margin / finalPricePreview) * 100;
  }

  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setDescription(String value) {
    description = value;
    notifyListeners();
  }

  void setImageUrl(String value) {
    imageUrl = value;
    notifyListeners();
  }

  void setSku(String value) {
    sku = value;
    notifyListeners();
  }

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }

  void setUnit(String value) {
    unit = value;
    notifyListeners();
  }

  void setRetailPrice(double value) {
    retailPrice = value;
    notifyListeners();
  }

  void setDiscountPercentage(double value) {
    discountPercentage = value.clamp(0, 100).toDouble();
    notifyListeners();
  }

  void setCostPrice(double value) {
    costPrice = value;
    notifyListeners();
  }

  void setStockQuantity(int value) {
    stockQuantity = value;
    notifyListeners();
  }

  void setStatus(ProductStatus value) {
    status = value;
    notifyListeners();
  }

  void addSize({
    required String label,
    required double price,
    double discountPercentage = 0,
    double? costPrice,
  }) {
    _sizes.add(
      ProductSizeModel.calculate(
        productId: '', // linked to the real product id in saveProduct()
        label: label,
        price: price,
        discountPercentage: discountPercentage,
        costPrice: (costPrice != null && costPrice > 0) ? costPrice : null,
        sortOrder: _sizes.length,
      ),
    );
    notifyListeners();
  }

  void removeSize(int index) {
    _sizes.removeAt(index);
    notifyListeners();
  }

  Future<bool> saveProduct() async {
    if (!canSave) {
      errorMessage = 'Enter a product name and a retail price above 0.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final product = ProductModel.calculate(
        id: _existingProduct?.id,
        name: name.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        imageUrl: imageUrl.trim().isEmpty ? null : imageUrl.trim(),
        sku: sku.trim().isEmpty ? null : sku.trim(),
        category: category.trim().isEmpty ? null : category.trim(),
        unit: unit.trim().isEmpty ? null : unit.trim(),
        retailPrice: retailPrice,
        discountPercentage: discountPercentage,
        costPrice: costPrice > 0 ? costPrice : null,
        stockQuantity: stockQuantity,
        status: status,
        isActive: _existingProduct?.isActive ?? true,
        sizes: _sizes,
        createdAt: _existingProduct?.createdAt,
      );

      // Sizes were created before the product existed (or carried
      // over from the existing one), so re-point them at the
      // product's real id right before persisting.
      final finalProduct = product.copyWith(
        sizes: _sizes.map((s) => s.attachToProduct(product.id)).toList(),
      );

      if (isEditing) {
        await _repository.updateProduct(finalProduct);
      } else {
        await _repository.createProduct(finalProduct);
        _resetForm();
      }
      return true;
    } catch (e) {
      errorMessage = 'Failed to save product: $e';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    name = '';
    description = '';
    imageUrl = '';
    sku = '';
    category = '';
    unit = '';
    retailPrice = 0;
    discountPercentage = 0;
    costPrice = 0;
    stockQuantity = 0;
    status = ProductStatus.inStock;
    _sizes.clear();
  }
}
