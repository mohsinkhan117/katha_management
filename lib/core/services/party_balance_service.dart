// lib/core/services/party_balance_service.dart

import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/features/order/data/repositories/sqflite_order_repository.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/payment/data/repositories/sqflite_payment_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sale_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sqflite_sale_repository.dart';

import '../models/party_balance_summary.dart';
import '../models/party_model.dart';
import '../models/payment/payment_model.dart';
import '../models/sale_model.dart';

/// Single, shared place that turns raw Sale/Order/Payment rows into a
/// party's unified balance.
///
/// Ensures Dashboard, Customers list, Orders, and Party History all calculate
/// the exact same balance dynamically:
/// balanceDue = party.openingBalance (previous due)
///            + sum(sales.totalAmount)
///            + sum(active orders.totalAmount)
///            - sum(payments.amount)
class PartyBalanceService {
  PartyBalanceService({
    SaleRepository? saleRepository,
    PaymentRepository? paymentRepository,
    OrderRepository? orderRepository,
  }) : _saleRepository = saleRepository ?? SqfliteSaleRepository(),
       _paymentRepository = paymentRepository ?? SqflitePaymentRepository(),
       _orderRepository = orderRepository ?? SqfliteOrderRepository();

  final SaleRepository _saleRepository;
  final PaymentRepository _paymentRepository;
  final OrderRepository _orderRepository;

  /// Balances for every party at once — used by the dashboard and the
  /// Customers list.
  Future<List<PartyBalanceSummary>> computeAll(List<PartyModel> parties) async {
    final sales = await _saleRepository.getAllSales();
    final payments = await _paymentRepository.getAllPayments();
    final orders = await _orderRepository.getAllOrders();
    return parties
        .map((party) => _computeFor(party, sales, payments, orders))
        .toList();
  }

  /// Balance for a single party — used by the Party History screen.
  Future<PartyBalanceSummary> computeForParty(PartyModel party) async {
    final sales = await _saleRepository.getAllSales();
    final payments = await _paymentRepository.getAllPayments();
    final orders = await _orderRepository.getAllOrders();
    return _computeFor(party, sales, payments, orders);
  }

  PartyBalanceSummary _computeFor(
    PartyModel party,
    List<SaleModel> allSales,
    List<PaymentModel> allPayments,
    List<OrderModel> allOrders,
  ) {
    final partySales = allSales.where(
      (sale) => belongsToParty(party, id: sale.partyId, name: sale.partyName),
    );

    final partyPayments = allPayments.where(
      (payment) =>
          belongsToParty(party, id: payment.partyId, name: payment.partyName),
    );

    final partyOrders = allOrders.where(
      (order) =>
          order.status != OrderStatus.cancelled &&
          belongsToParty(party, id: order.partyId, name: order.partyName),
    );

    final totalSales = partySales.fold(
      0.0,
      (sum, sale) => sum + sale.totalAmount,
    );

    final totalOrders = partyOrders.fold(
      0.0,
      (sum, order) => sum + order.totalAmount,
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

    for (final order in partyOrders) {
      if (order.balanceDue <= 0) continue;
      if (oldestPendingSaleDate == null ||
          order.orderDate.isBefore(oldestPendingSaleDate)) {
        oldestPendingSaleDate = order.orderDate;
      }
    }

    final balance =
        party.openingBalance + totalSales + totalOrders - totalCollected;

    if (balance > 0 &&
        party.openingBalance > 0 &&
        oldestPendingSaleDate == null) {
      oldestPendingSaleDate = party.createdAt;
    }

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
