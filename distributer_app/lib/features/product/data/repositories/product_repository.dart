// lib/features/product/data/repositories/product_repository.dart

import 'package:katha_management/core/models/product/product_model.dart';

/// Contract for anything that can persist/read products.
///
/// The ViewModel depends only on this interface — never on
/// `SqfliteProductRepository` directly — so a Firestore/sync
/// repository can replace it in Phase 5 without any change above
/// this layer.
///
/// Deliberately has no hard `deleteProduct` — see `setActive` and
/// `ProductModel.isActive`'s doc comment for why. A product that has
/// ever been used in a Sale or Order line item must never be
/// hard-deleted, since that would corrupt historical records that
/// still reference it by id.
abstract class ProductRepository {
  Future<void> createProduct(ProductModel product);

  Future<List<ProductModel>> getAllProducts({bool includeInactive = false});

  Future<ProductModel?> getProductById(String id);

  /// Case-insensitive match against name, SKU, or category.
  Future<List<ProductModel>> searchProducts(
    String query, {
    bool includeInactive = false,
  });

  Future<void> updateProduct(ProductModel product);

  /// Soft delete / restore — hides (or unhides) a product from the
  /// picker without touching anything that already references it.
  Future<void> setActive(String id, bool isActive);
}
