// lib/ui/products/product_list_view_model.dart

import 'package:flutter/material.dart';

import 'package:katha_management/core/models/product/product_model.dart';
import 'package:katha_management/features/product/data/repositories/product_repository.dart';
import 'package:katha_management/features/product/data/repositories/sqflite_product_repository.dart';

/// Feeds the Products screen: the catalog, filterable by category and
/// a name/SKU search.
class ProductListViewModel extends ChangeNotifier {
  ProductListViewModel({ProductRepository? repository})
    : _repository = repository ?? SqfliteProductRepository() {
    loadProducts();
  }

  final ProductRepository _repository;

  List<ProductModel> _allProducts = [];
  bool isLoading = false;
  String? errorMessage;

  String _query = '';
  String? _categoryFilter;

  String? get categoryFilter => _categoryFilter;

  List<String> get categories =>
      _allProducts.map((p) => p.category).whereType<String>().toSet().toList()
        ..sort();

  List<ProductModel> get products {
    var result = _allProducts;

    if (_categoryFilter != null) {
      result = result.where((p) => p.category == _categoryFilter).toList();
    }

    if (_query.trim().isNotEmpty) {
      final normalized = _query.trim().toLowerCase();
      result = result.where((p) {
        final nameMatches = p.name.toLowerCase().contains(normalized);
        final skuMatches = p.sku?.toLowerCase().contains(normalized) ?? false;
        return nameMatches || skuMatches;
      }).toList();
    }

    return result;
  }

  Future<void> loadProducts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _allProducts = await _repository.getAllProducts();
      _allProducts.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } catch (e) {
      errorMessage = 'Failed to load products: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  Future<void> toggleActive(ProductModel product) async {
    try {
      await _repository.setActive(product.id, !product.isActive);
      await loadProducts();
    } catch (e) {
      errorMessage = 'Failed to update product: $e';
      notifyListeners();
    }
  }

  Future<void> refresh() => loadProducts();
}
