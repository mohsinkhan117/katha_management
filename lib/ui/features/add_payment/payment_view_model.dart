// lib/ui/features/add_payment/payment_view_model.dart

import 'package:flutter/foundation.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/payment/payment_allocation_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/features/party/data/repositories/party_repository.dart';
import 'package:katha_management/features/party/data/repositories/sqflite_party_repository.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/payment/data/repositories/sqflite_payment_repository.dart';

/// Drives the Payments screen and payment recording logic.
class PaymentViewModel extends ChangeNotifier {
  PaymentViewModel({
    PaymentRepository? repository,
    PartyRepository? partyRepository,
  }) : _repository = repository ?? SqflitePaymentRepository(),
       _partyRepository = partyRepository ?? SqflitePartyRepository();

  final PaymentRepository _repository;
  final PartyRepository _partyRepository;

  List<PaymentModel> _payments = [];
  List<PaymentModel> get payments => _payments;

  List<PartyModel> _availableParties = [];
  List<PartyModel> get availableParties => _availableParties;

  PartyModel? _linkedParty;
  PartyModel? get linkedParty => _linkedParty;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadPayments({String? partyId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _availableParties = await _partyRepository.getAllParties();

      if (partyId != null) {
        _linkedParty = await _partyRepository.getPartyById(partyId);
        _payments = await _repository.getPaymentsByParty(partyId);
      } else {
        _linkedParty = null;
        _payments = await _repository.getAllPayments();
      }
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
    String? currentPartyId,
  }) async {
    _errorMessage = null;
    try {
      await _repository.insertPayment(payment, allocations: allocations);
      await loadPayments(partyId: currentPartyId ?? payment.partyId);
      return true;
    } catch (e) {
      _errorMessage = 'Could not save payment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePayment(
    PaymentModel payment, {
    String? currentPartyId,
  }) async {
    _errorMessage = null;
    try {
      await _repository.updatePayment(payment);
      await loadPayments(partyId: currentPartyId ?? payment.partyId);
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
