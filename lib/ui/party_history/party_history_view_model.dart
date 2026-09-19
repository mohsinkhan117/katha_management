// lib/ui/party_history/party_history_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/features/order/data/repositories/sqflite_order_repository.dart';
import 'package:katha_management/features/party/data/repositories/party_repository.dart';
import 'package:katha_management/features/party/data/repositories/sqflite_party_repository.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/payment/data/repositories/sqflite_payment_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sale_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sqflite_sale_repository.dart';

import '../../core/models/new_order/new_order_model.dart'; // ASSUMPTION: adjust to your real OrderModel path
import '../../core/models/party_balance_summary.dart';
import '../../core/models/party_model.dart';
import '../../core/models/payment/payment_model.dart';
import '../../core/models/sale_model.dart';
import '../../core/services/party_balance_service.dart';

enum PartyHistoryFilter { all, sales, orders, payments }

enum PartyHistoryEntryType { sale, order, payment }

/// One row in the Party History timeline — a display-only wrapper
/// around a Sale, Order, or Payment so all three can be merged, sorted,
/// and rendered together without the View needing to know the shape
/// of three different models.
class PartyHistoryEntry {
  final PartyHistoryEntryType type;
  final double amount;
  final DateTime date;
  final String title;
  final String? subtitle;

  const PartyHistoryEntry({
    required this.type,
    required this.amount,
    required this.date,
    required this.title,
    this.subtitle,
  });
}

/// Feeds the Party History screen: one party's full record across
/// Sales, Orders, and Payments, plus their live balance — this is the
/// screen that was missing entirely before.
class PartyHistoryViewModel extends ChangeNotifier {
  PartyHistoryViewModel({
    required this.partyId,
    PartyRepository? partyRepository,
    SaleRepository? saleRepository,
    OrderRepository? orderRepository,
    PaymentRepository? paymentRepository,
    PartyBalanceService? balanceService,
  }) : _partyRepository = partyRepository ?? SqflitePartyRepository(),
       _saleRepository = saleRepository ?? SqfliteSaleRepository(),
       _orderRepository = orderRepository ?? SqfliteOrderRepository(),
       _paymentRepository = paymentRepository ?? SqflitePaymentRepository(),
       _balanceService = balanceService ?? PartyBalanceService() {
    load();
  }

  final String partyId;
  final PartyRepository _partyRepository;
  final SaleRepository _saleRepository;
  final OrderRepository _orderRepository;
  final PaymentRepository _paymentRepository;
  final PartyBalanceService _balanceService;

  bool isLoading = false;
  String? errorMessage;

  PartyModel? party;
  PartyBalanceSummary? balance;

  List<SaleModel> sales = [];
  List<OrderModel> orders = [];
  List<PaymentModel> payments = [];

  PartyHistoryFilter filter = PartyHistoryFilter.all;

  List<PartyHistoryEntry> get timeline {
    final entries = <PartyHistoryEntry>[
      if (filter == PartyHistoryFilter.all ||
          filter == PartyHistoryFilter.sales)
        ...sales.map(
          (sale) => PartyHistoryEntry(
            type: PartyHistoryEntryType.sale,
            amount: sale.totalAmount,
            date: sale.saleDate,
            title: 'Sale',
            subtitle: sale.balanceDue > 0
                ? 'Rs ${sale.balanceDue.toStringAsFixed(0)} still due'
                : 'Fully paid',
          ),
        ),
      if (filter == PartyHistoryFilter.all ||
          filter == PartyHistoryFilter.orders)
        ...orders.map(
          (order) => PartyHistoryEntry(
            type: PartyHistoryEntryType.order,
            amount: order.totalAmount,
            date: order.orderDate,
            title: 'Order — ${order.status.label}',
          ),
        ),
      if (filter == PartyHistoryFilter.all ||
          filter == PartyHistoryFilter.payments)
        ...payments.map(
          (payment) => PartyHistoryEntry(
            type: PartyHistoryEntryType.payment,
            amount: payment.amount,
            date: payment.paymentDate,
            title: 'Payment received',
            subtitle: payment.note,
          ),
        ),
    ];

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  void setFilter(PartyHistoryFilter value) {
    filter = value;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final loadedParty = await _partyRepository.getPartyById(partyId);
      if (loadedParty == null) {
        errorMessage = 'This party could not be found.';
        return;
      }
      party = loadedParty;

      final results = await Future.wait([
        _saleRepository.getAllSales(),
        _orderRepository.getAllOrders(),
        _paymentRepository.getAllPayments(),
      ]);

      final allSales = results[0] as List<SaleModel>;
      final allOrders = results[1] as List<OrderModel>;
      final allPayments = results[2] as List<PaymentModel>;

      sales =
          allSales
              .where(
                (sale) => _balanceService.belongsToParty(
                  loadedParty,
                  id: sale.partyId,
                  name: sale.partyName,
                ),
              )
              .toList()
            ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

      orders =
          allOrders
              .where(
                (order) => _balanceService.belongsToParty(
                  loadedParty,
                  id: order.partyId,
                  name: order.partyName,
                ),
              )
              .toList()
            ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

      payments =
          allPayments
              .where(
                (payment) => _balanceService.belongsToParty(
                  loadedParty,
                  id: payment.partyId,
                  name: payment.partyName,
                ),
              )
              .toList()
            ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

      balance = await _balanceService.computeForParty(loadedParty);
    } catch (e) {
      errorMessage = 'Failed to load party history: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();
}
