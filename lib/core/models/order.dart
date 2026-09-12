// lib/core/models/order.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:katha_management/core/models/order_item.dart';

enum OrderStatus { open, submitted, invoiced, cancelled }

OrderStatus orderStatusFromString(String? value) {
  return OrderStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => OrderStatus.open,
  );
}

/// A table's in-progress or completed order. Created by the Order Review
/// screen once a [MenuItem] cart is confirmed; promoted to an Invoice once
/// printed.
class Order {
  final String id;
  final String tableId;
  final int tableNumber;
  final OrderStatus status;
  final List<OrderItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    required this.status,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  double get subtotal => items.fold(0, (total, item) => total + item.subtotal);

  Order copyWith({
    String? id,
    String? tableId,
    int? tableNumber,
    OrderStatus? status,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      status: status ?? this.status,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    return Order(
      id: id,
      tableId: map['tableId'] as String? ?? '',
      tableNumber: (map['tableNumber'] as num?)?.toInt() ?? 0,
      status: orderStatusFromString(map['status'] as String?),
      items: ((map['items'] as List?) ?? [])
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'tableNumber': tableNumber,
      'status': status.name,
      'items': items.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
