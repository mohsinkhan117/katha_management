// lib/core/services/party_balance_service.dart

import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/payment/data/repositories/sqflite_payment_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sale_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sqflite_sale_repository.dart';

import '../models/party_balance_summary.dart';
import '../models/party_model.dart';
import '../models/payment/payment_model.dart';
import '../models/sale_model.dart';

/// Single, shared place that turns raw Sale/Payment rows into a
/// party's balance.
///
/// This used to be duplicated logic living inside `HomeViewModel`.
/// Pulling it out here means the dashboard, the Customers list, and
/// the Party History screen all compute the exact same number the
/// exact same way — previously "receivables" on the dashboard could
/// silently disagree with a party's own balance shown elsewhere,
/// since each screen would have reimplemented this math itself.
class PartyBalanceService {
  PartyBalanceService({
    SaleRepository? saleRepository,
    PaymentRepository? paymentRepository,
  }) : _saleRepository = saleRepository ?? SqfliteSaleRepository(),
       _paymentRepository = paymentRepository ?? SqflitePaymentRepository();

  final SaleRepository _saleRepository;
  final PaymentRepository _paymentRepository;

  /// Balances for every party at once — used by the dashboard and the
  /// Customers list, where loading all sales/payments once and
  /// computing every party's balance in memory is far cheaper than
  /// one query per party.
  Future<List<PartyBalanceSummary>> computeAll(List<PartyModel> parties) async {
    final sales = await _saleRepository.getAllSales();
    final payments = await _paymentRepository.getAllPayments();
    return parties.map((party) => _computeFor(party, sales, payments)).toList();
  }

  /// Balance for a single party — used by the Party History screen.
  Future<PartyBalanceSummary> computeForParty(PartyModel party) async {
    final sales = await _saleRepository.getAllSales();
    final payments = await _paymentRepository.getAllPayments();
    return _computeFor(party, sales, payments);
  }

  PartyBalanceSummary _computeFor(
    PartyModel party,
    List<SaleModel> allSales,
    List<PaymentModel> allPayments,
  ) {
    final partySales = allSales.where(
      (sale) => belongsToParty(party, id: sale.partyId, name: sale.partyName),
    );

    final partyPayments = allPayments.where(
      (payment) =>
          belongsToParty(party, id: payment.partyId, name: payment.partyName),
    );

    final totalSales = partySales.fold(
      0.0,
      (sum, sale) => sum + sale.totalAmount,
    );

    final totalCollected = partyPayments.fold(
      0.0,
      (sum, payment) => sum + payment.amount,
    );

    DateTime? oldestPendingSaleDate;
    for (final sale in partySales) {
      if (sale.balanceDue <= 0) continue;
      if (oldestPendingSaleDate == null ||
          sale.saleDate.isBefore(oldestPendingSaleDate)) {
        oldestPendingSaleDate = sale.saleDate;
      }
    }

    final balance = party.openingBalance + totalSales - totalCollected;

    return PartyBalanceSummary(
      party: party,
      balanceDue: balance,
      oldestPendingSaleDate: oldestPendingSaleDate,
    );
  }

  /// Sales/Orders/Payments still fall back to free-text party names
  /// until every form is wired to a real Party picker — matches on
  /// `partyId` when present, otherwise falls back to a
  /// case-insensitive name match.
  ///
  /// Public (not private) so any screen that needs to filter a
  /// party's own records — Party History, for one — uses the exact
  /// same matching rule the balance calculation uses, rather than
  /// reimplementing it slightly differently.
  bool belongsToParty(
    PartyModel party, {
    required String? id,
    required String name,
  }) {
    if (id != null && id == party.id) return true;
    return name.trim().toLowerCase() == party.name.trim().toLowerCase();
  }
}
