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
/// of `createProduct` on save — same prefill pattern used by New Sale
/// / New Order when opened from a locked context.
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
      discountPrice = existingProduct.discountPrice ?? 0;
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
  double discountPrice = 0;
  double costPrice = 0;
  int? stockQuantity;
  ProductStatus status = ProductStatus.inStock;

  final List<ProductSizeModel> _sizes = [];
  List<ProductSizeModel> get sizes => List.unmodifiable(_sizes);

  bool isSaving = false;
  String? errorMessage;

  bool get canSave => name.trim().isNotEmpty && retailPrice > 0;

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

  void setDiscountPrice(double value) {
    discountPrice = value;
    notifyListeners();
  }

  void setCostPrice(double value) {
    costPrice = value;
    notifyListeners();
  }

  void setStockQuantity(int? value) {
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
    double? discountPrice,
  }) {
    _sizes.add(
      ProductSizeModel(
        productId: '', // linked to the real product id in saveProduct()
        label: label,
        price: price,
        discountPrice: discountPrice,
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
      final product = ProductModel(
        id: _existingProduct?.id,
        name: name.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        imageUrl: imageUrl.trim().isEmpty ? null : imageUrl.trim(),
        sku: sku.trim().isEmpty ? null : sku.trim(),
        category: category.trim().isEmpty ? null : category.trim(),
        unit: unit.trim().isEmpty ? null : unit.trim(),
        retailPrice: retailPrice,
        discountPrice: discountPrice > 0 ? discountPrice : null,
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
    discountPrice = 0;
    costPrice = 0;
    stockQuantity = null;
    status = ProductStatus.inStock;
    _sizes.clear();
  }
}
