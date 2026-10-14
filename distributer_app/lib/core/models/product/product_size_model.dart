// lib/core/models/product/product_size_model.dart

import 'package:uuid/uuid.dart';

/// One priced variant of a product — e.g. "1 Liter" at Rs 550,
/// "3 Liter" at Rs 1550.
///
/// The discount is stored as a **percentage** (0-100), not a flat
/// amount — a size's discount should scale automatically if its base
/// `price` is ever revised, rather than becoming a stale absolute
/// number that no longer matches the new price.
///
/// `finalPrice` is calculated **once**, at the moment this size is
/// created or edited, and stored alongside `price`/
/// `discountPercentage`. Every other read of this model (the New
/// Order picker, the product list, a receipt) uses the already-
/// computed `finalPrice` — the math only ever runs in one place:
/// [ProductSizeModel.calculate].
///
/// `costPrice` (optional) — what this specific size variant costs to
/// procure or produce. Enables calculation of `profitMargin` and
/// `profitMarginPercentage` per size variant.
class ProductSizeModel {
  final String id;
  final String productId;
  final String label; // "1 Liter", "5Kg", "Dozen", "Carton" — free text
  final double price; // base price, before discount
  final double discountPercentage; // 0-100
  final double finalPrice; // price after discount — computed once, stored
  final double? costPrice; // optional cost price per size variant
  final int sortOrder;

  ProductSizeModel({
    String? id,
    required this.productId,
    required this.label,
    required this.price,
    this.discountPercentage = 0,
    required this.finalPrice,
    this.costPrice,
    this.sortOrder = 0,
  }) : id = id ?? const Uuid().v4();

  /// The only place `finalPrice` is ever calculated from scratch.
  /// Use this whenever a size is newly created or its price/discount
  /// is being edited.
  factory ProductSizeModel.calculate({
    String? id,
    required String productId,
    required String label,
    required double price,
    double discountPercentage = 0,
    double? costPrice,
    int sortOrder = 0,
  }) {
    final clampedPercentage = discountPercentage.clamp(0, 100).toDouble();

    return ProductSizeModel(
      id: id,
      productId: productId,
      label: label,
      price: price,
      discountPercentage: clampedPercentage,
      finalPrice: calculateFinalPrice(price, clampedPercentage),
      costPrice: costPrice,
      sortOrder: sortOrder,
    );
  }

  /// Public so the Add Product form can show a live "you'll charge
  /// Rs X" preview while the user is still typing, using the exact
  /// same formula that gets baked into `finalPrice` on save.
  static double calculateFinalPrice(double price, double discountPercentage) {
    final discountAmount = price * (discountPercentage / 100);
    final result = price - discountAmount;
    return result < 0 ? 0 : result;
  }

  bool get hasDiscount => discountPercentage > 0;

  /// Profit per unit for this size. `null` when cost price is not provided.
  double? get profitMargin =>
      costPrice == null ? null : finalPrice - costPrice!;

  /// Profit as a percentage of the selling price for this size.
  double? get profitMarginPercentage {
    final margin = profitMargin;
    if (margin == null || finalPrice <= 0) return null;
    return (margin / finalPrice) * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'label': label,
      'price': price,
      'discountPercentage': discountPercentage,
      'finalPrice': finalPrice,
      'costPrice': costPrice,
      'sortOrder': sortOrder,
    };
  }

  factory ProductSizeModel.fromMap(Map<String, dynamic> map) {
    return ProductSizeModel(
      id: map['id'] as String,
      productId: map['productId'] as String,
      label: map['label'] as String,
      price: (map['price'] as num).toDouble(),
      discountPercentage: (map['discountPercentage'] as num?)?.toDouble() ?? 0,
      finalPrice: (map['finalPrice'] as num).toDouble(),
      costPrice: (map['costPrice'] as num?)?.toDouble(),
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  /// Returns a copy pointed at [productId]. Used once a [ProductModel]
  /// has generated its id, right before persisting.
  ProductSizeModel attachToProduct(String productId) {
    return ProductSizeModel(
      id: id,
      productId: productId,
      label: label,
      price: price,
      discountPercentage: discountPercentage,
      finalPrice: finalPrice,
      costPrice: costPrice,
      sortOrder: sortOrder,
    );
  }

  /// Recalculates `finalPrice` if [price] or [discountPercentage]
  /// change; otherwise carries the already-stored value forward
  /// unchanged rather than redoing arithmetic that hasn't gone stale.
  ProductSizeModel copyWith({
    String? label,
    double? price,
    double? discountPercentage,
    double? costPrice,
    int? sortOrder,
  }) {
    final newPrice = price ?? this.price;
    final newDiscount = discountPercentage ?? this.discountPercentage;
    final needsRecalculation = price != null || discountPercentage != null;

    return ProductSizeModel(
      id: id,
      productId: productId,
      label: label ?? this.label,
      price: newPrice,
      discountPercentage: newDiscount,
      finalPrice: needsRecalculation
          ? calculateFinalPrice(newPrice, newDiscount)
          : finalPrice,
      costPrice: costPrice ?? this.costPrice,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
