// lib/core/models/invoice.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:katha_management/core/models/order.dart' hide Order;
import 'package:katha_management/core/models/order.dart' as order_model;
import 'package:katha_management/core/models/order_item.dart';

/// A single invoice line item.
///
/// [name] and [unitPrice] are a snapshot taken at order time, never read
/// live from a menu when the invoice is printed — otherwise editing a menu
/// price later would silently rewrite historical invoices (tech spec §8).
class InvoiceItem {
  final String name;
  final double unitPrice;

  /// In units of the menu item's `quantityStep` at order time (e.g. 0.5,
  /// 1, 2). Kept as `double` to match `OrderItem.quantity` — an invoice
  /// built from an order with half-portions must be able to carry a 0.5
  /// through to print, not round it away.
  final double quantity;

  const InvoiceItem({
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

  factory InvoiceItem.fromOrderItem(OrderItem item) {
    return InvoiceItem(
      name: item.name,
      unitPrice: item.price,
      quantity: item.quantity,
    );
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      name: map['name'] as String? ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'unitPrice': unitPrice, 'quantity': quantity};
  }
}

/// Tracked separately from order state (tech spec §7) — a failed print must
/// never mean a lost or duplicated order.
enum PrintStatus { notPrinted, printing, printed, printFailed }

PrintStatus printStatusFromString(String? value) {
  return PrintStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => PrintStatus.notPrinted,
  );
}

/// Immutable once finalized, aside from [printStatus].
class Invoice {
  final String id;
  final String invoiceNumber;
  final String orderId;
  final String tableId;
  final int tableNumber;
  final List<InvoiceItem> items;

  /// Percent, e.g. 5.0 for 5%. Snapshotted from the hotel profile at the
  /// moment the invoice is generated — later changes to the tax rate must
  /// never retroactively change an already-issued invoice.
  final double taxRate;

  final DateTime createdAt;
  PrintStatus printStatus;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.orderId,
    required this.tableId,
    required this.tableNumber,
    required this.items,
    required this.taxRate,
    required this.createdAt,
    this.printStatus = PrintStatus.notPrinted,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get taxAmount => subtotal * taxRate / 100;
  double get total => subtotal + taxAmount;

  /// Builds the invoice to be saved for a just-finalized [order]. [id] and
  /// [invoiceNumber] are left blank here — [InvoiceService.createInvoice]
  /// fills both in once the Firestore document exists (the doc id is what
  /// the invoice number is derived from).
  factory Invoice.fromOrder(
    order_model.Order order, {
    required double taxRate,
  }) {
    return Invoice(
      id: '',
      invoiceNumber: '',
      orderId: order.id,
      tableId: order.tableId,
      tableNumber: order.tableNumber,
      items: order.items.map(InvoiceItem.fromOrderItem).toList(),
      taxRate: taxRate,
      createdAt: DateTime.now(),
    );
  }

  factory Invoice.fromMap(String id, Map<String, dynamic> map) {
    return Invoice(
      id: id,
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      orderId: map['orderId'] as String? ?? '',
      tableId: map['tableId'] as String? ?? '',
      tableNumber: (map['tableNumber'] as num?)?.toInt() ?? 0,
      items: ((map['items'] as List?) ?? [])
          .map((e) => InvoiceItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      printStatus: printStatusFromString(map['printStatus'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'orderId': orderId,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'items': items.map((e) => e.toMap()).toList(),
      'taxRate': taxRate,
      'printStatus': printStatus.name,
    };
  }
}
