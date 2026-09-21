// lib\core\models\product\product_model.dart
/*
Map<String, int> Sizes { '100g': 100, '250g': 500, '500g': 800, '1Kg': 1600, 5Kg, 10Kg, 100Kg} // the prices will be set by admin at product creation time, the hardcoded are jsut for example
UUid ProductId;
String ProductName;
string ProductDiscription;
string imageURL;
// the prices will be taken according to the sizes Map
int RetailPrice;
int discoutPrice;
DateTime createdAt;
DateTime updatedAt;
enum Status{ In stock, Out of Stock}

 */

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

/// A product in the catalog — what gets picked from when placing an
/// Order or recording a Sale, instead of typing a product name
/// freehand every time.
///
/// A few notes on fields beyond the original sketch:
/// - `stockQuantity` is kept separate from `status`. `status` is a
///   manual flag the seller sets directly ("mark Out of Stock"), true
///   the instant it's set; `stockQuantity` exists for a future
///   automatic low-stock warning. The two aren't forced to agree,
///   since a seller might mark something out of stock for reasons
///   unrelated to a tracked count (a size discontinued, for one).
/// - `isActive` is a soft-delete flag. A product already referenced
///   by a past Sale/Order line item must never be hard-deleted — that
///   would corrupt historical records. Discontinuing a product sets
///   `isActive = false` instead: hidden from the picker, history
///   stays intact.
class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? sku;
  final String? category;
  final String? unit; // e.g. "piece", "kg" — what the sizes are variants of
  final double retailPrice;
  final double? discountPrice;
  final double? costPrice;
  final int? stockQuantity;
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
    this.discountPrice,
    this.costPrice,
    this.stockQuantity,
    this.status = ProductStatus.inStock,
    this.isActive = true,
    this.sizes = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// The price to actually charge when no specific size is picked —
  /// the discount price if it's genuinely cheaper, otherwise retail.
  double get effectiveRetailPrice {
    if (discountPrice != null &&
        discountPrice! > 0 &&
        discountPrice! < retailPrice) {
      return discountPrice!;
    }
    return retailPrice;
  }

  bool get hasSizes => sizes.isNotEmpty;

  /// Simple default threshold — swap for a per-product configurable
  /// value later if needed; kept as a getter so nothing outside this
  /// model needs its own copy of the rule.
  bool get isLowStock => stockQuantity != null && stockQuantity! <= 5;

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
      'discountPrice': discountPrice,
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
      discountPrice: (map['discountPrice'] as num?)?.toDouble(),
      costPrice: (map['costPrice'] as num?)?.toDouble(),
      stockQuantity: (map['stockQuantity'] as num?)?.toInt(),
      status: ProductStatusX.fromString(map['status'] as String),
      isActive: (map['isActive'] as int?) == 1,
      sizes: sizes,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: (map['isSynced'] as int?) == 1,
    );
  }

  ProductModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    String? sku,
    String? category,
    String? unit,
    double? retailPrice,
    double? discountPrice,
    double? costPrice,
    int? stockQuantity,
    ProductStatus? status,
    bool? isActive,
    List<ProductSizeModel>? sizes,
    bool? isSynced,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      retailPrice: retailPrice ?? this.retailPrice,
      discountPrice: discountPrice ?? this.discountPrice,
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
