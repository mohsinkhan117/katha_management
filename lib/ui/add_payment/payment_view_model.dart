// lib\ui\add_payment\payment_view_model.dart

import 'package:flutter/foundation.dart';
import 'package:katha_management/core/models/payment/payment_allocation_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/payment/data/repositories/sqflite_payment_repository.dart';

/// Drives the payments screen. Exposed via `ChangeNotifierProvider` and
/// read in the view with `Consumer<PaymentViewModel>`.
class PaymentViewModel extends ChangeNotifier {
  PaymentViewModel({PaymentRepository? repository})
    : _repository = repository ?? SqflitePaymentRepository();

  final PaymentRepository _repository;

  List<PaymentModel> _payments = [];
  List<PaymentModel> get payments => _payments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadPayments({String? partyId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _payments = partyId == null
          ? await _repository.getAllPayments()
          : await _repository.getPaymentsByParty(partyId);
    } catch (e) {
      _errorMessage = 'Could not load payments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPayment(
    PaymentModel payment, {
    List<PaymentAllocationModel> allocations = const [],
  }) async {
    _errorMessage = null;
    try {
      await _repository.insertPayment(payment, allocations: allocations);
      await loadPayments(partyId: payment.partyId);
      return true;
    } catch (e) {
      _errorMessage = 'Could not save payment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePayment(PaymentModel payment) async {
    _errorMessage = null;
    try {
      await _repository.updatePayment(payment);
      await loadPayments(partyId: payment.partyId);
      return true;
    } catch (e) {
      _errorMessage = 'Could not update payment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePayment(String paymentId, {String? partyId}) async {
    _errorMessage = null;
    try {
      await _repository.deletePayment(paymentId);
      await loadPayments(partyId: partyId);
      return true;
    } catch (e) {
      _errorMessage = 'Could not delete payment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> allocatePayment(
    String paymentId,
    List<PaymentAllocationModel> allocations, {
    String? partyId,
  }) async {
    _errorMessage = null;
    try {
      await _repository.allocatePayment(paymentId, allocations);
      await loadPayments(partyId: partyId);
      return true;
    } catch (e) {
      _errorMessage = 'Could not allocate payment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<double> getUnallocatedAmount(String paymentId) {
    return _repository.getUnallocatedAmount(paymentId);
  }
}
