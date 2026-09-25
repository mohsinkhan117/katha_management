// test/party_history_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:katha_management/core/models/new_order/new_order_item_model.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/payment/payment_allocation_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/models/sale_item_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:katha_management/core/models/settings/hotel_profile_model.dart';
import 'package:katha_management/core/services/party_report_pdf_service.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/features/party/data/repositories/party_repository.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sale_repository.dart';
import 'package:katha_management/features/settings/data/repositories/settings_repository.dart';
import 'package:katha_management/ui/party_history/party_history_view_model.dart';

class MockPartyRepo implements PartyRepository {
  final PartyModel? party;
  MockPartyRepo(this.party);

  @override
  Future<void> createParty(PartyModel party) async {}
  @override
  Future<void> deleteParty(String id) async {}
  @override
  Future<List<PartyModel>> getAllParties() async =>
      party != null ? [party!] : [];
  @override
  Future<PartyModel?> getPartyById(String id) async =>
      party?.id == id ? party : null;
  @override
  Future<List<PartyModel>> searchParties(String query) async =>
      party != null ? [party!] : [];
  @override
  Future<void> updateParty(PartyModel party) async {}
}

class MockSaleRepo implements SaleRepository {
  final List<SaleModel> sales;
  MockSaleRepo(this.sales);

  @override
  Future<void> createSale(SaleModel sale) async => sales.add(sale);
  @override
  Future<List<SaleModel>> getAllSales() async => sales;
  @override
  Future<SaleModel?> getSaleById(String id) async =>
      sales.where((s) => s.id == id).firstOrNull;
  @override
  Future<List<SaleModel>> getSalesByParty(String partyId) async =>
      sales.where((s) => s.partyId == partyId).toList();
  @override
  Future<void> updateSale(SaleModel sale) async {}
  @override
  Future<void> deleteSale(String id) async =>
      sales.removeWhere((s) => s.id == id);
}

class MockOrderRepo implements OrderRepository {
  final List<OrderModel> orders;
  MockOrderRepo(this.orders);

  @override
  Future<void> createOrder(OrderModel order) async => orders.add(order);
  @override
  Future<List<OrderModel>> getAllOrders() async => orders;
  @override
  Future<OrderModel?> getOrderById(String id) async =>
      orders.where((o) => o.id == id).firstOrNull;
  @override
  Future<List<OrderModel>> getOrdersByParty(String partyId) async =>
      orders.where((o) => o.partyId == partyId).toList();
  @override
  Future<List<OrderModel>> getOrdersByStatus(OrderStatus status) async =>
      orders.where((o) => o.status == status).toList();
  @override
  Future<void> updateOrder(OrderModel order) async {
    final idx = orders.indexWhere((o) => o.id == order.id);
    if (idx != -1) orders[idx] = order;
  }

  @override
  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    final idx = orders.indexWhere((o) => o.id == id);
    if (idx != -1) orders[idx] = orders[idx].copyWith(status: status);
  }

  @override
  Future<void> deleteOrder(String id) async =>
      orders.removeWhere((o) => o.id == id);
}

class MockPaymentRepo implements PaymentRepository {
  final List<PaymentModel> payments;
  MockPaymentRepo(this.payments);

  @override
  Future<void> insertPayment(
    PaymentModel payment, {
    List<PaymentAllocationModel> allocations = const [],
  }) async => payments.add(payment);
  @override
  Future<List<PaymentModel>> getAllPayments() async => payments;
  @override
  Future<PaymentModel?> getPaymentById(String id) async =>
      payments.where((p) => p.id == id).firstOrNull;
  @override
  Future<List<PaymentModel>> getPaymentsByParty(String partyId) async =>
      payments.where((p) => p.partyId == partyId).toList();
  @override
  Future<List<PaymentAllocationModel>> getAllocationsForPayment(
    String paymentId,
  ) async => [];
  @override
  Future<List<PaymentAllocationModel>> getAllocationsForSale(
    String saleId,
  ) async => [];
  @override
  Future<void> allocatePayment(
    String paymentId,
    List<PaymentAllocationModel> allocations,
  ) async {}
  @override
  Future<double> getUnallocatedAmount(String paymentId) async => 0.0;
  @override
  Future<void> updatePayment(PaymentModel payment) async {}
  @override
  Future<void> deletePayment(String id) async =>
      payments.removeWhere((p) => p.id == id);
}

class MockSettingsRepo implements SettingsRepository {
  HotelProfileModel profile;
  MockSettingsRepo(this.profile);

  @override
  Future<HotelProfileModel> getProfile() async => profile;

  @override
  Future<void> saveProfile(HotelProfileModel newProfile) async {
    profile = newProfile;
  }
}

void main() {
  late PartyModel party;
  late OrderModel order;
  late SaleModel sale;
  late PaymentModel payment;
  late HotelProfileModel hotelProfile;

  setUp(() {
    party = PartyModel(
      id: 'party_123',
      name: 'Grand Hotel',
      phone: '03009876543',
      address: 'Main Mall Road, Lahore',
    );

    order = OrderModel(
      id: 'order_1',
      partyId: 'party_123',
      partyName: 'Grand Hotel',
      status: OrderStatus.placed,
      orderDate: DateTime(2026, 9, 20),
      expectedDeliveryDate: DateTime(2026, 9, 22),
      note: 'Deliver to back gate',
      items: [
        OrderItemModel(
          orderId: 'order_1',
          productName: 'Basmati Rice (5kg)',
          quantity: 2,
          unitPrice: 1200,
          discount: 100,
        ),
        OrderItemModel(
          orderId: 'order_1',
          productName: 'Cooking Oil (1 Liter)',
          quantity: 4,
          unitPrice: 500,
          discount: 0,
        ),
      ],
    );

    sale = SaleModel(
      id: 'sale_1',
      partyId: 'party_123',
      partyName: 'Grand Hotel',
      saleDate: DateTime(2026, 9, 18),
      paidAmount: 2000,
      note: 'Invoice #001',
      items: [
        SaleItemModel(
          saleId: 'sale_1',
          productName: 'Wheat Flour (10kg)',
          quantity: 1,
          unitPrice: 1500,
          discount: 0,
        ),
        SaleItemModel(
          saleId: 'sale_1',
          productName: 'Sugar (5kg)',
          quantity: 2,
          unitPrice: 800,
          discount: 0,
        ),
      ],
    );

    payment = PaymentModel(
      id: 'pay_1',
      partyId: 'party_123',
      partyName: 'Grand Hotel',
      amount: 2000,
      paymentDate: DateTime(2026, 9, 19),
      mode: PaymentMode.bankTransfer,
      note: 'Online Transfer Ref #1234',
    );

    hotelProfile = HotelProfileModel(
      hotelName: 'Al-Madina Traders',
      tagline: 'Wholesale & Retail Ledger',
      phone: '042-111-222-333',
      address: 'Wholesale Market Block B, Lahore',
    );
  });

  group('PartyHistoryViewModel Detailed Breakdown & Summary Stats', () {
    test(
      'Calculates summary statistics correctly and builds itemised timeline',
      () async {
        final vm = PartyHistoryViewModel(
          partyId: 'party_123',
          partyRepository: MockPartyRepo(party),
          saleRepository: MockSaleRepo([sale]),
          orderRepository: MockOrderRepo([order]),
          paymentRepository: MockPaymentRepo([payment]),
          settingsRepository: MockSettingsRepo(hotelProfile),
        );

        await vm.load();

        // Summary Statistics
        expect(vm.totalSalesAmount, 3100); // 1500 + 1600
        expect(vm.totalPaymentsAmount, 2000);
        expect(vm.totalOrdersCount, 1);
        expect(vm.pendingOrdersCount, 1);
        expect(vm.deliveredOrdersCount, 0);

        // Timeline Verification
        expect(vm.timeline.length, 3);
        final orderEntry = vm.timeline.firstWhere(
          (e) => e.type == PartyHistoryEntryType.order,
        );
        expect(orderEntry.order, isNotNull);
        expect(orderEntry.order!.items.length, 2);
        expect(orderEntry.order!.items[0].productName, 'Basmati Rice (5kg)');
        expect(orderEntry.order!.items[0].subtotal, 2300); // 2 * 1200 - 100
        expect(orderEntry.order!.items[1].productName, 'Cooking Oil (1 Liter)');
        expect(orderEntry.order!.items[1].subtotal, 2000); // 4 * 500
        expect(orderEntry.order!.note, 'Deliver to back gate');

        // Sale Entry Verification
        final saleEntry = vm.timeline.firstWhere(
          (e) => e.type == PartyHistoryEntryType.sale,
        );
        expect(saleEntry.sale, isNotNull);
        expect(saleEntry.sale!.items.length, 2);
        expect(saleEntry.sale!.balanceDue, 1100); // 3100 - 2000

        // Payment Entry Verification
        final paymentEntry = vm.timeline.firstWhere(
          (e) => e.type == PartyHistoryEntryType.payment,
        );
        expect(paymentEntry.payment, isNotNull);
        expect(paymentEntry.payment!.mode, PaymentMode.bankTransfer);
        expect(paymentEntry.payment!.amount, 2000);
      },
    );

    test('Allows updating order status dynamically', () async {
      final orderRepo = MockOrderRepo([order]);
      final vm = PartyHistoryViewModel(
        partyId: 'party_123',
        partyRepository: MockPartyRepo(party),
        saleRepository: MockSaleRepo([]),
        orderRepository: orderRepo,
        paymentRepository: MockPaymentRepo([]),
        settingsRepository: MockSettingsRepo(hotelProfile),
      );

      await vm.load();
      expect(vm.orders.first.status, OrderStatus.placed);
      expect(vm.pendingOrdersCount, 1);
      expect(vm.deliveredOrdersCount, 0);

      // Transition to delivered
      await vm.updateOrderStatus('order_1', OrderStatus.delivered);
      expect(vm.orders.first.status, OrderStatus.delivered);
      expect(vm.pendingOrdersCount, 1);
      expect(vm.deliveredOrdersCount, 1);

      // Transition to paid
      await vm.updateOrderStatus('order_1', OrderStatus.paid);
      expect(vm.orders.first.status, OrderStatus.paid);
      expect(vm.pendingOrdersCount, 0);
      expect(vm.deliveredOrdersCount, 1);
    });

    test(
      'PartyReportPdfService generates valid PDF byte document with complete history',
      () async {
        final pdfBytes = await PartyReportPdfService.generatePdf(
          party: party,
          balance: null,
          orders: [order],
          sales: [sale],
          payments: [payment],
          hotelProfile: hotelProfile,
        );

        expect(pdfBytes, isNotEmpty);
        // PDF documents always start with '%PDF-' header
        final header = String.fromCharCodes(pdfBytes.take(5));
        expect(header, '%PDF-');
      },
    );
  });
}
