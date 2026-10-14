// lib/features/payment/data/repositories/payment_repository.dart

import 'package:katha_management/core/models/payment/payment_allocation_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';

/// Contract for payment persistence. Concrete implementations (sqflite,
/// remote, in-memory for tests) plug in behind this so the view model
/// never talks to a `Database` directly.
abstract class PaymentRepository {
  Future<void> insertPayment(
    PaymentModel payment, {
    List<PaymentAllocationModel> allocations,
  });

  Future<void> updatePayment(PaymentModel payment);

  Future<void> deletePayment(String paymentId);

  Future<PaymentModel?> getPaymentById(String paymentId);

  Future<List<PaymentModel>> getAllPayments();

  Future<List<PaymentModel>> getPaymentsByParty(String partyId);

  Future<List<PaymentAllocationModel>> getAllocationsForPayment(
    String paymentId,
  );

  Future<List<PaymentAllocationModel>> getAllocationsForSale(String saleId);

  /// Applies [allocations] against outstanding sales for an existing
  /// payment, updating each sale's `paidAmount`/`status` accordingly.
  /// The sum of [allocations] must not exceed the payment's amount
  /// minus whatever is already allocated.
  Future<void> allocatePayment(
    String paymentId,
    List<PaymentAllocationModel> allocations,
  );

  /// Amount of the payment not yet applied to any sale.
  Future<double> getUnallocatedAmount(String paymentId);
}
