// lib/features/payment/data/models/payment_model.dart

import 'package:uuid/uuid.dart';

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

/// A payment received from a party. May be fully or partially
/// allocated against outstanding sales via [PaymentAllocationModel] —
/// any amount left unallocated is treated as an on-account credit
/// (an advance) for that party.
class PaymentModel {
  final String id;
  final String? partyId;
  final String partyName;
  final String? partyPhone;
  final double amount;
  final DateTime paymentDate;
  final PaymentMode mode;
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
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4(),
       paymentDate = paymentDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

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

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      partyId: map['partyId'] as String?,
      partyName: map['partyName'] as String,
      partyPhone: map['partyPhone'] as String?,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      mode: PaymentModeX.fromString(map['mode'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: (map['isSynced'] as int?) == 1,
    );
  }
}
