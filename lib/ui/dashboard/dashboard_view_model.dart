// lib/ui/dashboard/dashboard_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/party_balance_summary.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:katha_management/core/services/party_balance_service.dart';
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

/// Feeds the Dashboard (Home) screen with live ledger metrics and activity.
class DashboardViewmodel extends ChangeNotifier {
  DashboardViewmodel({
    SaleRepository? saleRepository,
    OrderRepository? orderRepository,
    PaymentRepository? paymentRepository,
    PartyRepository? partyRepository,
    PartyBalanceService? balanceService,
  }) : _saleRepository = saleRepository ?? SqfliteSaleRepository(),
       _orderRepository = orderRepository ?? SqfliteOrderRepository(),
       _paymentRepository = paymentRepository ?? SqflitePaymentRepository(),
       _partyRepository = partyRepository ?? SqflitePartyRepository(),
       _balanceService = balanceService ?? PartyBalanceService() {
    loadDashboardData();
  }

  final SaleRepository _saleRepository;
  final OrderRepository _orderRepository;
  final PaymentRepository _paymentRepository;
  final PartyRepository _partyRepository;
  final PartyBalanceService _balanceService;

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

      final balances = await _balanceService.computeAll(parties);

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
