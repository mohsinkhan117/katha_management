// lib\core\models\payment\payment_model.dart

import 'package:uuid/uuid.dart';

import 'payment_allocation_model.dart';

enum PaymentMode { cash, bankTransfer, cheque, online, other }

extension PaymentModeX on PaymentMode {
  String get value => name;

  String get label {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.cheque:
        return 'Cheque';
      case PaymentMode.online:
        return 'Online / Wallet';
      case PaymentMode.other:
        return 'Other';
    }
  }

  static PaymentMode fromString(String value) {
    return PaymentMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => PaymentMode.cash,
    );
  }
}

/// A payment received from a party.
///
/// [allocations] record which sale(s) this payment settled, in whole
/// or in part. `amount - totalAllocated` is money left on account —
/// an advance the party has paid that isn't yet applied to a bill.
class PaymentModel {
  final String id;
  final String? partyId;
  final String partyName;
  final String? partyPhone;
  final double amount;
  final DateTime paymentDate;
  final PaymentMode mode;
  final List<PaymentAllocationModel> allocations;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  PaymentModel({
    String? id,
    this.partyId,
    required this.partyName,
    this.partyPhone,
    required this.amount,
    DateTime? paymentDate,
    this.mode = PaymentMode.cash,
    this.allocations = const [],
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : id = id ?? const Uuid().v4(),
        paymentDate = paymentDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get totalAllocated =>
      allocations.fold(0, (sum, a) => sum + a.amountApplied);

  double get unallocatedAmount => amount - totalAllocated;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partyId': partyId,
      'partyName': partyName,
      'partyPhone': partyPhone,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'mode': mode.value,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// `allocations` is passed in separately since it comes from the
  /// `payment_allocations` table, not the `payments` row itself.
  factory PaymentModel.fromMap(
    Map<String, dynamic> map, {
    List<PaymentAllocationModel> allocations = const [],
  }) {
    return PaymentModel(
      id: map['id'] as String,
      partyId: map['partyId'] as String?,
      partyName: map['partyName'] as String,
      partyPhone: map['partyPhone'] as String?,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      mode: PaymentModeX.fromString(map['mode'] as String),
      allocations: allocations,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: (map['isSynced'] as int?) == 1,
    );
  }
}