// lib/core/models/product/product_model.dart

import 'package:uuid/uuid.dart';

import 'product_size_model.dart';

enum ProductStatus { inStock, outOfStock }

extension ProductStatusX on ProductStatus {
  String get value => name;

  String get label {
    switch (this) {
      case ProductStatus.inStock:
        return 'In Stock';
      case ProductStatus.outOfStock:
        return 'Out of Stock';
    }
  }

  static ProductStatus fromString(String value) {
    return ProductStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ProductStatus.inStock,
    );
  }
}

/// A product in the catalog.
///
/// **Pricing fields, explained:**
/// - `retailPrice` — the sticker price, before any discount.
/// - `discountPercentage` (0-100) — how much is knocked off
///   `retailPrice`. Stored as a percentage rather than a flat amount
///   so it stays meaningful even if `retailPrice` is revised later.
/// - `finalPrice` — what the customer actually pays. Calculated
///   **once**, at the moment the product is created or edited (see
///   [ProductModel.calculate]), and stored here rather than
///   recalculated on every read. Every screen that needs "the price"
///   — the product list, the New Order picker, a receipt — reads
///   this field directly.
/// - `costPrice` (optional) — what the product costs *you* to buy or
///   produce. Together with `finalPrice`, this is what lets
///   `profitMargin`/`profitMarginPercentage` below (and a future
///   Reports screen) show actual profit, not just revenue.
class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? sku;
  final String? category;
  final String? unit; // e.g. "piece", "kg" — what the sizes are variants of
  final double retailPrice;
  final double discountPercentage; // 0-100
  final double finalPrice; // retailPrice after discount — computed, stored
  final double? costPrice;
  final int stockQuantity;
  final ProductStatus status;
  final bool isActive;
  final List<ProductSizeModel> sizes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  ProductModel({
    String? id,
    required this.name,
    this.description,
    this.imageUrl,
    this.sku,
    this.category,
    this.unit,
    required this.retailPrice,
    this.discountPercentage = 0,
    required this.finalPrice,
    this.costPrice,
    this.stockQuantity = 0,
    this.status = ProductStatus.inStock,
    this.isActive = true,
    this.sizes = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// The only place `finalPrice` is ever calculated from scratch.
  /// Use this whenever a product is newly created or its
  /// price/discount is being edited.
  factory ProductModel.calculate({
    String? id,
    required String name,
    String? description,
    String? imageUrl,
    String? sku,
    String? category,
    String? unit,
    required double retailPrice,
    double discountPercentage = 0,
    double? costPrice,
    int stockQuantity = 0,
    ProductStatus status = ProductStatus.inStock,
    bool isActive = true,
    List<ProductSizeModel> sizes = const [],
    DateTime? createdAt,
    bool isSynced = false,
  }) {
    final clampedPercentage = discountPercentage.clamp(0, 100).toDouble();

    return ProductModel(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      sku: sku,
      category: category,
      unit: unit,
      retailPrice: retailPrice,
      discountPercentage: clampedPercentage,
      finalPrice: calculateFinalPrice(retailPrice, clampedPercentage),
      costPrice: costPrice,
      stockQuantity: stockQuantity,
      status: status,
      isActive: isActive,
      sizes: sizes,
      createdAt: createdAt,
      isSynced: isSynced,
    );
  }

  /// Public so the Add Product form can show a live "customer pays
  /// Rs X" preview while the user is still typing, using the exact
  /// same formula that gets baked into `finalPrice` on save.
  static double calculateFinalPrice(double price, double discountPercentage) {
    final discountAmount = price * (discountPercentage / 100);
    final result = price - discountAmount;
    return result < 0 ? 0 : result;
  }

  bool get hasSizes => sizes.isNotEmpty;

  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 5;

  bool get hasDiscount => discountPercentage > 0;

  /// How much money is knocked off per unit versus the sticker price.
  double get discountAmount => retailPrice - finalPrice;

  /// Profit per unit. `null` (not zero) when no cost price has been
  /// entered, so the UI can tell "not tracked" apart from "breaking even".
  double? get profitMargin =>
      costPrice == null ? null : finalPrice - costPrice!;

  /// Profit as a percentage of the selling price — the margin % a
  /// retailer actually thinks in, not markup-on-cost.
  double? get profitMarginPercentage {
    final margin = profitMargin;
    if (margin == null || finalPrice <= 0) return null;
    return (margin / finalPrice) * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'sku': sku,
      'category': category,
      'unit': unit,
      'retailPrice': retailPrice,
      'discountPercentage': discountPercentage,
      'finalPrice': finalPrice,
      'costPrice': costPrice,
      'stockQuantity': stockQuantity,
      'status': status.value,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// `sizes` is passed in separately since it comes from the
  /// `product_sizes` table, not the `products` row itself.
  factory ProductModel.fromMap(
    Map<String, dynamic> map, {
    List<ProductSizeModel> sizes = const [],
  }) {
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      sku: map['sku'] as String?,
      category: map['category'] as String?,
      unit: map['unit'] as String?,
      retailPrice: (map['retailPrice'] as num).toDouble(),
      discountPercentage: (map['discountPercentage'] as num?)?.toDouble() ?? 0,
      finalPrice: (map['finalPrice'] as num).toDouble(),
      costPrice: (map['costPrice'] as num?)?.toDouble(),
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 0,
      status: ProductStatusX.fromString(map['status'] as String),
      isActive: (map['isActive'] as int?) == 1,
      sizes: sizes,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: (map['isSynced'] as int?) == 1,
    );
  }

  /// Recalculates `finalPrice` if `retailPrice` or
  /// `discountPercentage` change; otherwise carries the already-
  /// stored value forward unchanged.
  ProductModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    String? sku,
    String? category,
    String? unit,
    double? retailPrice,
    double? discountPercentage,
    double? costPrice,
    int? stockQuantity,
    ProductStatus? status,
    bool? isActive,
    List<ProductSizeModel>? sizes,
    bool? isSynced,
  }) {
    final newRetailPrice = retailPrice ?? this.retailPrice;
    final newDiscount = discountPercentage ?? this.discountPercentage;
    final needsRecalculation =
        retailPrice != null || discountPercentage != null;

    return ProductModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      retailPrice: newRetailPrice,
      discountPercentage: newDiscount,
      finalPrice: needsRecalculation
          ? calculateFinalPrice(newRetailPrice, newDiscount)
          : finalPrice,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      sizes: sizes ?? this.sizes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
