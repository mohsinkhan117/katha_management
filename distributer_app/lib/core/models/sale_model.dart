// lib\core\models\sale_model.dart

import 'package:katha_management/core/models/sale_item_model.dart';
import 'package:uuid/uuid.dart';

enum SaleStatus { paid, partial, pending }

extension SaleStatusX on SaleStatus {
  String get value => name;

  static SaleStatus fromString(String value) {
    return SaleStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SaleStatus.pending,
    );
  }
}

/// A single sale made to a party (customer/shop).
///
/// `totalAmount` and `status` are derived from [items]/[paidAmount] but
/// are also stored on the row (see [toMap]) so dashboard queries (e.g.
/// "today's sales", "total receivables") can sum a column directly
/// instead of loading every sale's items into memory.
class SaleModel {
  final String id;
  final String? partyId;
  final String partyName;
  final String? partyPhone;
  final DateTime saleDate;
  final List<SaleItemModel> items;
  final double paidAmount;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  SaleModel({
    String? id,
    this.partyId,
    required this.partyName,
    this.partyPhone,
    DateTime? saleDate,
    required this.items,
    this.paidAmount = 0,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4(),
       saleDate = saleDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  double get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);

  double get balanceDue => totalAmount - paidAmount;

  SaleStatus get status {
    if (paidAmount <= 0) return SaleStatus.pending;
    if (paidAmount >= totalAmount) return SaleStatus.paid;
    return SaleStatus.partial;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partyId': partyId,
      'partyName': partyName,
      'partyPhone': partyPhone,
      'saleDate': saleDate.toIso8601String(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status.value,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// `items` is passed in separately since it comes from the
  /// `sale_items` table, not the `sales` row itself.
  factory SaleModel.fromMap(
    Map<String, dynamic> map, {
    List<SaleItemModel> items = const [],
  }) {
    return SaleModel(
      id: map['id'] as String,
      partyId: map['partyId'] as String?,
      partyName: map['partyName'] as String,
      partyPhone: map['partyPhone'] as String?,
      saleDate: DateTime.parse(map['saleDate'] as String),
      items: items,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: (map['isSynced'] as int?) == 1,
    );
  }

  SaleModel copyWith({
    String? partyId,
    String? partyName,
    String? partyPhone,
    DateTime? saleDate,
    List<SaleItemModel>? items,
    double? paidAmount,
    String? note,
    bool? isSynced,
  }) {
    return SaleModel(
      id: id,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      partyPhone: partyPhone ?? this.partyPhone,
      saleDate: saleDate ?? this.saleDate,
      items: items ?? this.items,
      paidAmount: paidAmount ?? this.paidAmount,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
