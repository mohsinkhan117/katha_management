// lib/core/models/product/product_size_model.dart

import 'package:uuid/uuid.dart';

/// One priced variant of a product — e.g. "250g" at Rs 500, "1Kg" at
/// Rs 1800. A product can have zero size variants (it's just sold at
/// its flat `retailPrice`) or several — the picker in New Sale / New
/// Order will show these instead of a single price once that's wired
/// up.
class ProductSizeModel {
  final String id;
  final String productId;
  final String label; // "100g", "1Kg", "Dozen", "Carton" — free text
  final double price;
  final double? discountPrice;
  final int sortOrder;

  ProductSizeModel({
    String? id,
    required this.productId,
    required this.label,
    required this.price,
    this.discountPrice,
    this.sortOrder = 0,
  }) : id = id ?? const Uuid().v4();

  /// The price to actually charge — the discount price if one is set
  /// and it's genuinely cheaper, otherwise the regular price.
  double get effectivePrice {
    if (discountPrice != null && discountPrice! > 0 && discountPrice! < price) {
      return discountPrice!;
    }
    return price;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'label': label,
      'price': price,
      'discountPrice': discountPrice,
      'sortOrder': sortOrder,
    };
  }

  factory ProductSizeModel.fromMap(Map<String, dynamic> map) {
    return ProductSizeModel(
      id: map['id'] as String,
      productId: map['productId'] as String,
      label: map['label'] as String,
      price: (map['price'] as num).toDouble(),
      discountPrice: (map['discountPrice'] as num?)?.toDouble(),
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  /// Returns a copy pointed at [productId]. Used once a [ProductModel]
  /// has generated its id, right before persisting — same pattern as
  /// `SaleItemModel.attachToSale` / `OrderItemModel.attachToOrder`.
  ProductSizeModel attachToProduct(String productId) {
    return ProductSizeModel(
      id: id,
      productId: productId,
      label: label,
      price: price,
      discountPrice: discountPrice,
      sortOrder: sortOrder,
    );
  }

  ProductSizeModel copyWith({
    String? label,
    double? price,
    double? discountPrice,
    int? sortOrder,
  }) {
    return ProductSizeModel(
      id: id,
      productId: productId,
      label: label ?? this.label,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
