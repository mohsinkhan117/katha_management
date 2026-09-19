// test/ledger_and_orders_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:katha_management/core/models/new_order/new_order_item_model.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/models/sale_item_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:katha_management/core/services/party_balance_service.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sale_repository.dart';

class MockSaleRepository implements SaleRepository {
  final List<SaleModel> sales = [];
  @override
  Future<void> createSale(SaleModel sale) async => sales.add(sale);
  @override
  Future<void> deleteSale(String id) async =>
      sales.removeWhere((s) => s.id == id);
  @override
  Future<List<SaleModel>> getAllSales() async => sales;
  @override
  Future<SaleModel?> getSaleById(String id) async =>
      sales.firstWhere((s) => s.id == id);
  @override
  Future<List<SaleModel>> getSalesByParty(String partyId) async =>
      sales.where((s) => s.partyId == partyId).toList();
  @override
  Future<void> updateSale(SaleModel sale) async {
    final idx = sales.indexWhere((s) => s.id == sale.id);
    if (idx != -1) sales[idx] = sale;
  }
}

class MockPaymentRepository implements PaymentRepository {
  final List<PaymentModel> payments = [];
  @override
  Future<void> insertPayment(
    PaymentModel payment, {
    List<dynamic> allocations = const [],
  }) async => payments.add(payment);
  @override
  Future<void> deletePayment(String paymentId) async =>
      payments.removeWhere((p) => p.id == paymentId);
  @override
  Future<List<PaymentModel>> getAllPayments() async => payments;
  @override
  Future<PaymentModel?> getPaymentById(String paymentId) async =>
      payments.firstWhere((p) => p.id == paymentId);
  @override
  Future<List<PaymentModel>> getPaymentsByParty(String partyId) async =>
      payments.where((p) => p.partyId == partyId).toList();
  @override
  Future<void> updatePayment(PaymentModel payment) async {
    final idx = payments.indexWhere((p) => p.id == payment.id);
    if (idx != -1) payments[idx] = payment;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Ledger and Balance Calculations', () {
    test(
      'PartyBalanceService computes openingBalance + sales - payments correctly',
      () async {
        final mockSaleRepo = MockSaleRepository();
        final mockPaymentRepo = MockPaymentRepository();
        final balanceService = PartyBalanceService(
          saleRepository: mockSaleRepo,
          paymentRepository: mockPaymentRepo,
        );

        final party = PartyModel(
          id: 'party-1',
          name: 'Ali Traders',
          openingBalance: 1000,
        );

        // Sale 1: Rs 500
        mockSaleRepo.sales.add(
          SaleModel(
            id: 'sale-1',
            partyId: 'party-1',
            partyName: 'Ali Traders',
            items: [
              SaleItemModel(
                saleId: 'sale-1',
                productName: 'Item A',
                quantity: 5,
                unitPrice: 100,
              ),
            ],
            paidAmount: 200,
          ),
        );

        // Sale 2: Rs 300
        mockSaleRepo.sales.add(
          SaleModel(
            id: 'sale-2',
            partyId: 'party-1',
            partyName: 'Ali Traders',
            items: [
              SaleItemModel(
                saleId: 'sale-2',
                productName: 'Item B',
                quantity: 3,
                unitPrice: 100,
              ),
            ],
            paidAmount: 0,
          ),
        );

        // Payment 1: Rs 400
        mockPaymentRepo.payments.add(
          PaymentModel(
            id: 'pay-1',
            partyId: 'party-1',
            partyName: 'Ali Traders',
            amount: 400,
          ),
        );

        final summary = await balanceService.computeForParty(party);

        // Total Sales = 500 + 300 = 800
        // Total Payments = 400
        // Opening Balance = 1000
        // Expected Balance Due = 1000 + 800 - 400 = 1400
        expect(summary.balanceDue, equals(1400.0));
        expect(summary.partyName, equals('Ali Traders'));
      },
    );
  });

  group('Order Status Transitions', () {
    test(
      'OrderStatus moves through placed -> confirmed -> dispatched -> delivered',
      () {
        expect(OrderStatus.placed.next, equals(OrderStatus.confirmed));
        expect(OrderStatus.confirmed.next, equals(OrderStatus.dispatched));
        expect(OrderStatus.dispatched.next, equals(OrderStatus.delivered));
        expect(OrderStatus.delivered.next, isNull);
        expect(OrderStatus.cancelled.next, isNull);

        expect(OrderStatus.placed.isTerminal, isFalse);
        expect(OrderStatus.confirmed.isTerminal, isFalse);
        expect(OrderStatus.dispatched.isTerminal, isFalse);
        expect(OrderStatus.delivered.isTerminal, isTrue);
        expect(OrderStatus.cancelled.isTerminal, isTrue);
      },
    );

    test('OrderModel computes item count and total amount correctly', () {
      final order = OrderModel(
        partyName: 'Test Customer',
        items: [
          OrderItemModel(
            orderId: 'o1',
            productName: 'P1',
            quantity: 2,
            unitPrice: 250,
          ),
          OrderItemModel(
            orderId: 'o1',
            productName: 'P2',
            quantity: 1,
            unitPrice: 100,
            discount: 10,
          ),
        ],
      );

      expect(order.itemCount, equals(2));
      // 2 * 250 + (1 * 100 - 10) = 500 + 90 = 590
      expect(order.totalAmount, equals(590.0));
    });
  });
}
