// lib\core\models\sale_item_model.dart

import 'package:uuid/uuid.dart';

/// A single product line on a [SaleModel].
///
/// `productId` is nullable on purpose: right now items are entered as
/// free text (no Product module yet). Once the Product module (Phase 2)
/// exists, the UI can start passing a real `productId` here without
/// any change to this model or the database schema.
class SaleItemModel {
  final String id;
  final String saleId;
  final String? productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;

  SaleItemModel({
    String? id,
    required this.saleId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
  }) : id = id ?? const Uuid().v4();

  double get subtotal => (quantity * unitPrice) - discount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
    };
  }

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'] as String,
      saleId: map['saleId'] as String,
      productId: map['productId'] as String?,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Returns a copy of this item pointed at [saleId]. Used once a
  /// [SaleModel] has generated its id, right before persisting.
  SaleItemModel attachToSale(String saleId) {
    return SaleItemModel(
      id: id,
      saleId: saleId,
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      discount: discount,
    );
  }

  SaleItemModel copyWith({
    String? productName,
    double? quantity,
    double? unitPrice,
    double? discount,
  }) {
    return SaleItemModel(
      id: id,
      saleId: saleId,
      productId: productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
    );
  }
}
