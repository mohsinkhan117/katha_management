// lib\core\models\new_order\new_order_model.dart

import 'package:katha_management/core/models/new_order/new_order_item_model.dart';
import 'package:uuid/uuid.dart';

enum OrderStatus { placed, confirmed, dispatched, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get value => name;

  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.dispatched:
        return 'Dispatched';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// The next status in the normal flow. Null once an order reaches a
  /// terminal state (delivered / cancelled).
  OrderStatus? get next {
    switch (this) {
      case OrderStatus.placed:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.dispatched;
      case OrderStatus.dispatched:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return null;
    }
  }

  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.placed,
    );
  }
}

/// An order placed by a party, tracked through
/// placed → confirmed → dispatched → delivered (or cancelled).
///
/// An Order carries no payment — it's a commitment, not a transaction.
/// Once delivered, it's expected to be converted into a Sale/Invoice
/// (see the Sale module), which is where money actually changes hands.
class OrderModel {
  final String id;
  final String? partyId;
  final String partyName;
  final String? partyPhone;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final List<OrderItemModel> items;
  final OrderStatus status;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  OrderModel({
    String? id,
    this.partyId,
    required this.partyName,
    this.partyPhone,
    DateTime? orderDate,
    this.expectedDeliveryDate,
    required this.items,
    this.status = OrderStatus.placed,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4(),
       orderDate = orderDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  double get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => items.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partyId': partyId,
      'partyName': partyName,
      'partyPhone': partyPhone,
      'orderDate': orderDate.toIso8601String(),
      'expectedDeliveryDate': expectedDeliveryDate?.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status.value,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// `items` is passed in separately since it comes from the
  /// `order_items` table, not the `orders` row itself.
  factory OrderModel.fromMap(
    Map<String, dynamic> map, {
    List<OrderItemModel> items = const [],
  }) {
    return OrderModel(
      id: map['id'] as String,
      partyId: map['partyId'] as String?,
      partyName: map['partyName'] as String,
      partyPhone: map['partyPhone'] as String?,
      orderDate: DateTime.parse(map['orderDate'] as String),
      expectedDeliveryDate: map['expectedDeliveryDate'] != null
          ? DateTime.parse(map['expectedDeliveryDate'] as String)
          : null,
      items: items,
      status: OrderStatusX.fromString(map['status'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: (map['isSynced'] as int?) == 1,
    );
  }

  OrderModel copyWith({
    String? partyId,
    String? partyName,
    String? partyPhone,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    List<OrderItemModel>? items,
    OrderStatus? status,
    String? note,
    bool? isSynced,
  }) {
    return OrderModel(
      id: id,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      partyPhone: partyPhone ?? this.partyPhone,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      items: items ?? this.items,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
