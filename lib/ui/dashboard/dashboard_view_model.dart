// lib/features/home/logic/home_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/features/order/data/repositories/sqflite_order_repository.dart';
import 'package:katha_management/features/party/data/repositories/party_repository.dart';
import 'package:katha_management/features/party/data/repositories/sqflite_party_repository.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/payment/data/repositories/sqflite_payment_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sale_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sqflite_sale_repository.dart';

enum ActivityType { sale, payment, order }

/// A single row in the dashboard's "Recent Activity" feed.
///
/// This is a display-only view built by merging Sale, Payment, and
/// Order records — it isn't persisted anywhere itself.
class ActivityItem {
  final ActivityType type;
  final String partyName;
  final double amount;
  final DateTime date;

  const ActivityItem({
    required this.type,
    required this.partyName,
    required this.amount,
    required this.date,
  });
}

/// A party's outstanding balance as shown on the dashboard.
///
/// `balanceDue` = opening balance + unpaid sales - unapplied advance
/// payments. This is computed fresh on every load rather than stored
/// anywhere (see `PartyModel`'s doc comment on why). Once a dedicated
/// Ledger module exists, this computation belongs there instead —
/// this class will likely become that module's output type.
class PartyBalanceSummary {
  final String partyId;
  final String partyName;
  final String? partyPhone;
  final double balanceDue;
  final DateTime? oldestPendingSaleDate;

  const PartyBalanceSummary({
    required this.partyId,
    required this.partyName,
    this.partyPhone,
    required this.balanceDue,
    this.oldestPendingSaleDate,
  });

  int? get daysSinceOldestDue {
    if (oldestPendingSaleDate == null) return null;
    return DateTime.now().difference(oldestPendingSaleDate!).inDays;
  }
}

/// Feeds the Dashboard (Home) screen with live data pulled from
/// sqflite via the Sale/Order/Payment/Party repositories.
///
/// All aggregation (today's totals, receivables, top pending parties)
/// happens here rather than in the View, so the View stays pure
/// presentation — and so this logic can move wholesale into a
/// dedicated Ledger/Reports repository later without the View ever
/// needing to change.
class DashboardViewmodel extends ChangeNotifier {
  DashboardViewmodel({
    SaleRepository? saleRepository,
    OrderRepository? orderRepository,
    PaymentRepository? paymentRepository,
    PartyRepository? partyRepository,
  }) : _saleRepository = saleRepository ?? SqfliteSaleRepository(),
       _orderRepository = orderRepository ?? SqfliteOrderRepository(),
       _paymentRepository = paymentRepository ?? SqflitePaymentRepository(),
       _partyRepository = partyRepository ?? SqflitePartyRepository() {
    loadDashboardData();
  }

  final SaleRepository _saleRepository;
  final OrderRepository _orderRepository;
  final PaymentRepository _paymentRepository;
  final PartyRepository _partyRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? errorMessage;

  double todaySales = 0;
  double todayCollection = 0;
  double totalReceivables = 0;
  int totalPartiesCount = 0;

  List<PartyBalanceSummary> topPendingParties = [];
  List<ActivityItem> recentActivity = [];

  Future<void> loadDashboardData() async {
    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Fetched in parallel — these four calls don't depend on each
      // other, so there's no reason to await them one at a time.
      final results = await Future.wait([
        _saleRepository.getAllSales(),
        _orderRepository.getAllOrders(),
        _paymentRepository.getAllPayments(),
        _partyRepository.getAllParties(),
      ]);

      final sales = results[0] as List<SaleModel>;
      final orders = results[1] as List<OrderModel>;
      final payments = results[2] as List<PaymentModel>;
      final parties = results[3] as List<PartyModel>;

      bool isToday(DateTime date) {
        final now = DateTime.now();
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }

      todaySales = sales
          .where((sale) => isToday(sale.saleDate))
          .fold(0.0, (sum, sale) => sum + sale.totalAmount);

      todayCollection = payments
          .where((payment) => isToday(payment.paymentDate))
          .fold(0.0, (sum, payment) => sum + payment.amount);

      totalPartiesCount = parties.length;

      final balances = _buildPartyBalances(parties, sales, payments);

      totalReceivables = balances
          .where((p) => p.balanceDue > 0)
          .fold(0.0, (sum, p) => sum + p.balanceDue);

      topPendingParties = balances.where((p) => p.balanceDue > 0).toList()
        ..sort((a, b) => b.balanceDue.compareTo(a.balanceDue));
      topPendingParties = topPendingParties.take(5).toList();

      recentActivity = _buildRecentActivity(sales, payments, orders);
    } catch (e) {
      errorMessage = 'Failed to load dashboard: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadDashboardData();

  List<PartyBalanceSummary> _buildPartyBalances(
    List<PartyModel> parties,
    List<SaleModel> sales,
    List<PaymentModel> payments,
  ) {
    return parties.map((party) {
      final partySales = sales.where(
        (sale) =>
            _belongsToParty(party, id: sale.partyId, name: sale.partyName),
      );

      final partyPayments = payments.where(
        (payment) => _belongsToParty(
          party,
          id: payment.partyId,
          name: payment.partyName,
        ),
      );

      final salesBalance = partySales.fold(
        0.0,
        (sum, sale) => sum + sale.balanceDue,
      );

      // Money received but not yet applied to a specific bill reduces
      // what the party still owes overall.
      final unallocatedAdvance = partyPayments.fold(
        0.0,
        (sum, payment) => sum + payment.unallocatedAmount,
      );

      DateTime? oldestPendingSaleDate;
      for (final sale in partySales) {
        if (sale.balanceDue <= 0) continue;
        if (oldestPendingSaleDate == null ||
            sale.saleDate.isBefore(oldestPendingSaleDate)) {
          oldestPendingSaleDate = sale.saleDate;
        }
      }

      final balance = party.openingBalance + salesBalance - unallocatedAdvance;

      return PartyBalanceSummary(
        partyId: party.id,
        partyName: party.name,
        partyPhone: party.phone,
        balanceDue: balance,
        oldestPendingSaleDate: oldestPendingSaleDate,
      );
    }).toList();
  }

  /// Sales/Orders/Payments still fall back to free-text party names
  /// until every module is wired to a real Party picker — matches on
  /// `partyId` when present, otherwise falls back to a
  /// case-insensitive name match.
  bool _belongsToParty(
    PartyModel party, {
    required String? id,
    required String name,
  }) {
    if (id != null && id == party.id) return true;
    return name.trim().toLowerCase() == party.name.trim().toLowerCase();
  }

  List<ActivityItem> _buildRecentActivity(
    List<SaleModel> sales,
    List<PaymentModel> payments,
    List<OrderModel> orders,
  ) {
    final items = <ActivityItem>[
      ...sales.map(
        (sale) => ActivityItem(
          type: ActivityType.sale,
          partyName: sale.partyName,
          amount: sale.totalAmount,
          date: sale.saleDate,
        ),
      ),
      ...payments.map(
        (payment) => ActivityItem(
          type: ActivityType.payment,
          partyName: payment.partyName,
          amount: payment.amount,
          date: payment.paymentDate,
        ),
      ),
      ...orders.map(
        (order) => ActivityItem(
          type: ActivityType.order,
          partyName: order.partyName,
          amount: order.totalAmount,
          date: order.orderDate,
        ),
      ),
    ];

    items.sort((a, b) => b.date.compareTo(a.date));
    return items.take(10).toList();
  }
}
