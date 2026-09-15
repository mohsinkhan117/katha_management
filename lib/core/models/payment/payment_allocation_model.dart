// lib\core\models\payment\payment_allocation_model.dart
import 'package:uuid/uuid.dart';

/// Records that [amountApplied] of a payment ([paymentId]) was applied
/// against a specific sale ([saleId]). A payment can have zero, one,
/// or many allocations; whatever isn't allocated is an on-account
/// advance for that party (see [PaymentModel]).
class PaymentAllocationModel {
  final String id;
  final String paymentId;
  final String saleId;
  final double amountApplied;

  PaymentAllocationModel({
    String? id,
    required this.paymentId,
    required this.saleId,
    required this.amountApplied,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'saleId': saleId,
      'amountApplied': amountApplied,
    };
  }

  factory PaymentAllocationModel.fromMap(Map<String, dynamic> map) {
    return PaymentAllocationModel(
      id: map['id'] as String,
      paymentId: map['paymentId'] as String,
      saleId: map['saleId'] as String,
      amountApplied: (map['amountApplied'] as num).toDouble(),
    );
  }
}
