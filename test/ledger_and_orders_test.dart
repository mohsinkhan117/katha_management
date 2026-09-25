// test/ledger_and_orders_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:katha_management/core/models/new_order/new_order_item_model.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/payment/payment_allocation_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/models/product/product_model.dart';
import 'package:katha_management/core/models/sale_item_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:katha_management/core/services/party_balance_service.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/features/party/data/repositories/party_repository.dart';
import 'package:katha_management/features/payment/data/repositories/payment_repository.dart';
import 'package:katha_management/features/product/data/repositories/product_repository.dart';
import 'package:katha_management/features/sale/data/repositories/sale_repository.dart';
import 'package:katha_management/ui/customers/customers_view_model.dart';
import 'package:katha_management/ui/features/add_party/add_party_view_model.dart';
import 'package:katha_management/ui/features/new_order/new_order_view_model.dart';
import 'package:katha_management/ui/features/new_sale/new_sale_view_model.dart';
import 'package:katha_management/ui/orders/order_view_model.dart';

class MockPartyRepository implements PartyRepository {
  final List<PartyModel> parties = [];
  @override
  Future<void> createParty(PartyModel party) async => parties.add(party);
  @override
  Future<void> deleteParty(String id) async =>
      parties.removeWhere((p) => p.id == id);
  @override
  Future<List<PartyModel>> getAllParties() async => parties;
  @override
  Future<PartyModel?> getPartyById(String id) async =>
      parties.where((p) => p.id == id).firstOrNull;
  @override
  Future<List<PartyModel>> searchParties(String query) async => parties
      .where(
        (p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            (p.phone?.contains(query) ?? false),
      )
      .toList();
  @override
  Future<void> updateParty(PartyModel party) async {
    final idx = parties.indexWhere((p) => p.id == party.id);
    if (idx != -1) parties[idx] = party;
  }
}

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
    List<PaymentAllocationModel> allocations = const [],
  }) async => payments.add(payment);
  @override
  Future<void> deletePayment(String paymentId) async =>
      payments.removeWhere((p) => p.id == paymentId);
  @override
  Future<List<PaymentModel>> getAllPayments() async => payments;
  @override
  Future<PaymentModel?> getPaymentById(String paymentId) async =>
      payments.where((p) => p.id == paymentId).firstOrNull;
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
  Future<void> updatePayment(PaymentModel payment) async {
    final idx = payments.indexWhere((p) => p.id == payment.id);
    if (idx != -1) payments[idx] = payment;
  }
}

class MockOrderRepository implements OrderRepository {
  final List<OrderModel> orders = [];
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

class MockProductRepository implements ProductRepository {
  final List<ProductModel> products = [];
  @override
  Future<void> createProduct(ProductModel product) async =>
      products.add(product);
  @override
  Future<List<ProductModel>> getAllProducts({
    bool includeInactive = false,
  }) async => products;
  @override
  Future<ProductModel?> getProductById(String id) async =>
      products.where((p) => p.id == id).firstOrNull;
  @override
  Future<List<ProductModel>> searchProducts(
    String query, {
    bool includeInactive = false,
  }) async => products
      .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
  @override
  Future<void> setActive(String id, bool isActive) async {}
  @override
  Future<void> updateProduct(ProductModel product) async {
    final idx = products.indexWhere((p) => p.id == product.id);
    if (idx != -1) products[idx] = product;
  }
}

void main() {
  group('Ledger and Balance Calculations', () {
    test(
      'PartyBalanceService computes openingBalance + sales - payments correctly',
      () async {
        final mockSaleRepo = MockSaleRepository();
        final mockPaymentRepo = MockPaymentRepository();
        final mockOrderRepo = MockOrderRepository();
        final balanceService = PartyBalanceService(
          saleRepository: mockSaleRepo,
          paymentRepository: mockPaymentRepo,
          orderRepository: mockOrderRepo,
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
    test('OrderStatus moves through placed -> delivered -> paid', () {
      expect(OrderStatus.placed.next, equals(OrderStatus.delivered));
      expect(OrderStatus.delivered.next, equals(OrderStatus.paid));
      expect(OrderStatus.paid.next, isNull);
      expect(OrderStatus.cancelled.next, isNull);

      expect(OrderStatus.placed.isTerminal, isFalse);
      expect(OrderStatus.delivered.isTerminal, isFalse);
      expect(OrderStatus.paid.isTerminal, isTrue);
      expect(OrderStatus.cancelled.isTerminal, isTrue);
    });

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
      expect(order.balanceDue, equals(590.0));
      expect(order.paymentStatus, equals(OrderPaymentStatus.unpaid));
    });

    test('OrderModel tracks advancePaid, balanceDue, and paymentStatus', () {
      final order = OrderModel(
        partyName: 'Advance Customer',
        advancePaid: 200,
        items: [
          OrderItemModel(
            orderId: 'o2',
            productName: 'P1',
            quantity: 2,
            unitPrice: 250,
          ),
        ],
      );

      // Total = 500, Advance = 200 => Balance = 300
      expect(order.totalAmount, equals(500.0));
      expect(order.advancePaid, equals(200.0));
      expect(order.balanceDue, equals(300.0));
      expect(order.paymentStatus, equals(OrderPaymentStatus.partial));

      final fullyPaidOrder = order.copyWith(advancePaid: 500);
      expect(fullyPaidOrder.balanceDue, equals(0.0));
      expect(fullyPaidOrder.paymentStatus, equals(OrderPaymentStatus.paid));
    });

    test(
      'OrderViewModel marks order as Paid and settles remaining balance',
      () async {
        final orderRepo = MockOrderRepository();
        final paymentRepo = MockPaymentRepository();

        final order = OrderModel(
          id: 'order_100',
          partyId: 'party_1',
          partyName: 'Test Hotel',
          status: OrderStatus.placed,
          advancePaid: 200,
          items: [
            OrderItemModel(
              orderId: 'order_100',
              productName: 'Item 1',
              quantity: 1,
              unitPrice: 1000,
            ),
          ],
        );
        orderRepo.orders.add(order);

        final vm = OrderViewModel(
          orderRepository: orderRepo,
          paymentRepository: paymentRepo,
        );
        await vm.loadOrders();

        expect(vm.pendingCount, 1);
        expect(vm.doneCount, 0);

        // Advance from placed -> delivered
        await vm.advanceStatus(order);
        expect(vm.allOrders.first.status, OrderStatus.delivered);
        expect(vm.pendingCount, 1);
        expect(vm.doneCount, 0);

        // Advance from delivered -> paid (Total = 1000, advance was 200 => settles remaining 800)
        await vm.advanceStatus(vm.allOrders.first);
        expect(vm.allOrders.first.status, OrderStatus.paid);
        expect(vm.allOrders.first.advancePaid, 1000.0);
        expect(vm.allOrders.first.balanceDue, 0.0);
        expect(vm.pendingCount, 0);
        expect(vm.doneCount, 1);

        // Verify payment was recorded for the remaining 800
        expect(paymentRepo.payments.length, 1);
        expect(paymentRepo.payments.first.amount, 800.0);
        expect(paymentRepo.payments.first.partyId, 'party_1');
      },
    );
  });

  group('Instant Party Auto-Creation', () {
    test(
      'NewSaleViewModel auto-creates PartyModel when saving sale with new customer',
      () async {
        final partyRepo = MockPartyRepository();
        final saleRepo = MockSaleRepository();
        final paymentRepo = MockPaymentRepository();
        final productRepo = MockProductRepository();

        final vm = NewSaleViewModel(
          partyRepository: partyRepo,
          repository: saleRepo,
          paymentRepository: paymentRepo,
          productRepository: productRepo,
        );

        vm.setPartyManual(name: 'Instant Customer', phone: '03001234567');
        vm.addCustomItem(
          productName: 'Custom Item',
          quantity: 2,
          unitPrice: 500,
        );
        vm.setPaidAmount(300);

        final success = await vm.saveSale();
        expect(success, isTrue);

        // Verify party was created in party repository
        expect(partyRepo.parties.length, 1);
        final createdParty = partyRepo.parties.first;
        expect(createdParty.name, 'Instant Customer');
        expect(createdParty.phone, '03001234567');

        // Verify sale and payment are linked to the newly created party id
        expect(saleRepo.sales.first.partyId, createdParty.id);
        expect(paymentRepo.payments.first.partyId, createdParty.id);
      },
    );

    test(
      'NewOrderViewModel auto-creates PartyModel when saving order with new customer',
      () async {
        final partyRepo = MockPartyRepository();
        final orderRepo = MockOrderRepository();
        final paymentRepo = MockPaymentRepository();
        final productRepo = MockProductRepository();

        final vm = NewOrderViewModel(
          partyRepository: partyRepo,
          repository: orderRepo,
          paymentRepository: paymentRepo,
          productRepository: productRepo,
        );

        vm.setPartyManual(name: 'New Order Customer', phone: '03119876543');
        vm.addCustomItem(
          productName: 'Order Item',
          quantity: 1,
          unitPrice: 1500,
        );
        vm.setAdvancePaid(500);

        final success = await vm.saveOrder();
        expect(success, isTrue);

        // Verify party was created in party repository
        expect(partyRepo.parties.length, 1);
        final createdParty = partyRepo.parties.first;
        expect(createdParty.name, 'New Order Customer');
        expect(createdParty.phone, '03119876543');

        // Verify order and advance payment are linked to the newly created party id
        expect(orderRepo.orders.first.partyId, createdParty.id);
        expect(paymentRepo.payments.first.partyId, createdParty.id);
      },
    );
  });

  group('CRUD Operations on Party Profile and Orders', () {
    test('AddPartyViewModel allows editing existing party profile', () async {
      final partyRepo = MockPartyRepository();
      final initialParty = PartyModel(
        id: 'party_edit_1',
        name: 'Original Shop',
        phone: '03001112233',
        address: 'Old Bazaar',
        openingBalance: 500,
        tag: PartyTag.retail,
        note: 'Original note',
      );
      partyRepo.parties.add(initialParty);

      final vm = AddPartyViewModel(
        partyToEdit: initialParty,
        repository: partyRepo,
      );

      expect(vm.isEditing, isTrue);
      expect(vm.name, 'Original Shop');
      expect(vm.phone, '03001112233');
      expect(vm.openingBalance, 500);

      // Mutate party details
      vm.setName('Updated Super Store');
      vm.setPhone('03009998877');
      vm.setAddress('Main Market');
      vm.setOpeningBalance(750);
      vm.setTag(PartyTag.wholesale);
      vm.setNote('Updated note');

      final saved = await vm.saveParty();
      expect(saved, isTrue);

      final updated = partyRepo.parties.firstWhere(
        (p) => p.id == 'party_edit_1',
      );
      expect(updated.name, 'Updated Super Store');
      expect(updated.phone, '03009998877');
      expect(updated.address, 'Main Market');
      expect(updated.openingBalance, 750);
      expect(updated.tag, PartyTag.wholesale);
      expect(updated.note, 'Updated note');
    });

    test('AddPartyViewModel allows deleting party', () async {
      final partyRepo = MockPartyRepository();
      final party = PartyModel(id: 'p_del_1', name: 'Delete Me');
      partyRepo.parties.add(party);

      final vm = AddPartyViewModel(partyToEdit: party, repository: partyRepo);

      final deleted = await vm.deleteParty();
      expect(deleted, isTrue);
      expect(partyRepo.parties.isEmpty, isTrue);
    });

    test('CustomersViewModel deletes party successfully', () async {
      final partyRepo = MockPartyRepository();
      final balanceService = PartyBalanceService(
        saleRepository: MockSaleRepository(),
        paymentRepository: MockPaymentRepository(),
        orderRepository: MockOrderRepository(),
      );
      partyRepo.parties.add(
        PartyModel(id: 'cust_del', name: 'Customer To Delete'),
      );

      final vm = CustomersViewModel(
        partyRepository: partyRepo,
        balanceService: balanceService,
      );
      await vm.loadParties();
      expect(vm.parties.length, 1);

      final deleted = await vm.deleteParty('cust_del');
      expect(deleted, isTrue);
      expect(vm.parties.isEmpty, isTrue);
    });

    test('NewOrderViewModel allows editing order in placed status', () async {
      final orderRepo = MockOrderRepository();
      final partyRepo = MockPartyRepository();
      final paymentRepo = MockPaymentRepository();
      final productRepo = MockProductRepository();

      final existingOrder = OrderModel(
        id: 'ord_placed_1',
        partyId: 'party_1',
        partyName: 'Ali Grocery',
        status: OrderStatus.placed,
        advancePaid: 100,
        items: [
          OrderItemModel(
            orderId: 'ord_placed_1',
            productName: 'Flour 10kg',
            quantity: 1,
            unitPrice: 1200,
          ),
        ],
      );
      orderRepo.orders.add(existingOrder);

      final vm = NewOrderViewModel(
        orderToEdit: existingOrder,
        repository: orderRepo,
        partyRepository: partyRepo,
        paymentRepository: paymentRepo,
        productRepository: productRepo,
      );

      expect(vm.isEditing, isTrue);
      expect(vm.canEdit, isTrue);
      expect(vm.partyName, 'Ali Grocery');
      expect(vm.totalAmount, 1200.0);

      // Edit items and advance
      vm.addCustomItem(productName: 'Sugar 5kg', quantity: 1, unitPrice: 600);
      vm.setAdvancePaid(300);
      vm.setNote('Urgent morning delivery');

      final saved = await vm.saveOrder();
      expect(saved, isTrue);

      final updated = orderRepo.orders.firstWhere(
        (o) => o.id == 'ord_placed_1',
      );
      expect(updated.items.length, 2);
      expect(updated.totalAmount, 1800.0);
      expect(updated.advancePaid, 300.0);
      expect(updated.balanceDue, 1500.0);
      expect(updated.note, 'Urgent morning delivery');
    });

    test(
      'NewOrderViewModel blocks editing and deleting when order is delivered or paid',
      () async {
        final orderRepo = MockOrderRepository();
        final partyRepo = MockPartyRepository();
        final paymentRepo = MockPaymentRepository();
        final productRepo = MockProductRepository();

        // Delivered Order
        final deliveredOrder = OrderModel(
          id: 'ord_deliv',
          partyName: 'Delivered Customer',
          status: OrderStatus.delivered,
          items: [
            OrderItemModel(
              orderId: 'ord_deliv',
              productName: 'Item Delivered',
              quantity: 1,
              unitPrice: 500,
            ),
          ],
        );
        orderRepo.orders.add(deliveredOrder);

        final vmDelivered = NewOrderViewModel(
          orderToEdit: deliveredOrder,
          repository: orderRepo,
          partyRepository: partyRepo,
          paymentRepository: paymentRepo,
          productRepository: productRepo,
        );

        expect(vmDelivered.isEditing, isTrue);
        expect(vmDelivered.canEdit, isFalse);

        final editAttempt = await vmDelivered.saveOrder();
        expect(editAttempt, isFalse);
        expect(vmDelivered.errorMessage, contains('Delivered or Paid'));

        final deleteAttempt = await vmDelivered.deleteOrder();
        expect(deleteAttempt, isFalse);
        expect(vmDelivered.errorMessage, contains('Delivered or Paid'));

        // Paid Order
        final paidOrder = OrderModel(
          id: 'ord_paid',
          partyName: 'Paid Customer',
          status: OrderStatus.paid,
          items: [
            OrderItemModel(
              orderId: 'ord_paid',
              productName: 'Item Paid',
              quantity: 1,
              unitPrice: 500,
            ),
          ],
        );
        orderRepo.orders.add(paidOrder);

        final vmPaid = NewOrderViewModel(
          orderToEdit: paidOrder,
          repository: orderRepo,
          partyRepository: partyRepo,
          paymentRepository: paymentRepo,
          productRepository: productRepo,
        );

        expect(vmPaid.isEditing, isTrue);
        expect(vmPaid.canEdit, isFalse);

        final paidEditAttempt = await vmPaid.saveOrder();
        expect(paidEditAttempt, isFalse);
        expect(vmPaid.errorMessage, contains('Delivered or Paid'));
      },
    );

    test('NewOrderViewModel allows deleting order in placed status', () async {
      final orderRepo = MockOrderRepository();
      final partyRepo = MockPartyRepository();
      final paymentRepo = MockPaymentRepository();
      final productRepo = MockProductRepository();

      final placedOrder = OrderModel(
        id: 'ord_placed_to_delete',
        partyName: 'Placed Customer',
        status: OrderStatus.placed,
        items: [
          OrderItemModel(
            orderId: 'ord_placed_to_delete',
            productName: 'Item Placed',
            quantity: 1,
            unitPrice: 500,
          ),
        ],
      );
      orderRepo.orders.add(placedOrder);

      final vm = NewOrderViewModel(
        orderToEdit: placedOrder,
        repository: orderRepo,
        partyRepository: partyRepo,
        paymentRepository: paymentRepo,
        productRepository: productRepo,
      );

      expect(vm.canEdit, isTrue);
      final deleted = await vm.deleteOrder();
      expect(deleted, isTrue);
      expect(orderRepo.orders.isEmpty, isTrue);
    });
  });
}
