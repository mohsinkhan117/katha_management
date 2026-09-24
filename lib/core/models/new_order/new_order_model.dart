// lib/core/models/new_order/new_order_model.dart

import 'package:katha_management/core/models/new_order/new_order_item_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:uuid/uuid.dart';

enum OrderStatus { placed, confirmed, dispatched, delivered, cancelled }

enum OrderPaymentStatus { unpaid, partial, paid }

extension OrderPaymentStatusX on OrderPaymentStatus {
  String get label {
    switch (this) {
      case OrderPaymentStatus.unpaid:
        return 'Unpaid';
      case OrderPaymentStatus.partial:
        return 'Partial Advance';
      case OrderPaymentStatus.paid:
        return 'Fully Paid';
    }
  }
}

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
/// Supports advance payments collected at order time. Once delivered,
/// it's converted into a Sale/Invoice with advance payments cleanly carried over.
class OrderModel {
  final String id;
  final String? partyId;
  final String partyName;
  final String? partyPhone;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final List<OrderItemModel> items;
  final OrderStatus status;
  final double advancePaid;
  final PaymentMode paymentMode;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  /// Set once this order has produced a Sale via `convertToSale()`.
  /// `null` means it hasn't been converted yet. This is the guard
  /// that stops an order being converted to a sale more than once —
  /// see `OrderViewModel.convertToSale`.
  final String? convertedSaleId;

  OrderModel({
    String? id,
    this.partyId,
    required this.partyName,
    this.partyPhone,
    DateTime? orderDate,
    this.expectedDeliveryDate,
    required this.items,
    this.status = OrderStatus.placed,
    this.advancePaid = 0.0,
    this.paymentMode = PaymentMode.cash,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.convertedSaleId,
  }) : id = id ?? const Uuid().v4(),
       orderDate = orderDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  double get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => items.length;

  double get balanceDue =>
      (totalAmount - advancePaid).clamp(0.0, double.infinity);

  OrderPaymentStatus get paymentStatus {
    if (advancePaid <= 0) return OrderPaymentStatus.unpaid;
    if (advancePaid >= totalAmount && totalAmount > 0) {
      return OrderPaymentStatus.paid;
    }
    return OrderPaymentStatus.partial;
  }

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
      'advancePaid': advancePaid,
      'paymentMode': paymentMode.value,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'convertedSaleId': convertedSaleId,
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
      advancePaid: (map['advancePaid'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['paymentMode'] != null
          ? PaymentModeX.fromString(map['paymentMode'] as String)
          : PaymentMode.cash,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: (map['isSynced'] as int?) == 1,
      convertedSaleId: map['convertedSaleId'] as String?,
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
    double? advancePaid,
    PaymentMode? paymentMode,
    String? note,
    bool? isSynced,
    String? convertedSaleId,
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
      advancePaid: advancePaid ?? this.advancePaid,
      paymentMode: paymentMode ?? this.paymentMode,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
      convertedSaleId: convertedSaleId ?? this.convertedSaleId,
    );
  }
}
