// lib\core\models\new_order\new_order_item_model.dart

import 'package:uuid/uuid.dart';

/// A single product line on an [OrderModel].
///
/// Structurally identical to `SaleItemModel` by design — an Order is
/// converted into a Sale/Invoice once delivered, so keeping the shape
/// consistent makes that conversion a straight field copy later.
/// 
/// I think we don't need this model anymore bcs we will be using product model
class OrderItemModel {
  final String id;
  final String orderId;
  final String? productId; 
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;

  OrderItemModel({
    String? id,
    required this.orderId,
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
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as String,
      orderId: map['orderId'] as String,
      productId: map['productId'] as String?,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Returns a copy of this item pointed at [orderId]. Used once an
  /// [OrderModel] has generated its id, right before persisting.
  OrderItemModel attachToOrder(String orderId) {
    return OrderItemModel(
      id: id,
      orderId: orderId,
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      discount: discount,
    );
  }

  OrderItemModel copyWith({
    String? productName,
    double? quantity,
    double? unitPrice,
    double? discount,
  }) {
    return OrderItemModel(
      id: id,
      orderId: orderId,
      productId: productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
    );
  }
}