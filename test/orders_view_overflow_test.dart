import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/models/new_order/new_order_item_model.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/theme/app_themes/themes.dart';
import 'package:katha_management/features/order/data/repositories/order_repository.dart';
import 'package:katha_management/l10n/app_localizations.dart';
import 'package:katha_management/ui/orders/order_view_model.dart';
import 'package:katha_management/ui/orders/orders_view.dart';

class _FakeOrderRepository implements OrderRepository {
  final List<OrderModel> orders = [];
  @override
  Future<void> createOrder(OrderModel order) async => orders.add(order);
  @override
  Future<void> deleteOrder(String id) async => orders.removeWhere((o) => o.id == id);
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
}

void main() {
  testWidgets('OrdersView _OrderCard renders in Urdu RTL on narrow screen without overflow',
      (WidgetTester tester) async {
    final fakeRepo = _FakeOrderRepository();
    final order = OrderModel(
      id: 'order_1',
      partyId: 'party_1',
      partyName: 'Cheif',
      partyPhone: '0378816161691',
      orderDate: DateTime(2026, 9, 23),
      updatedAt: DateTime(2026, 9, 23, 17, 18),
      expectedDeliveryDate: DateTime(2026, 9, 30),
      status: OrderStatus.placed,
      items: [
        OrderItemModel(
          orderId: 'order_1',
          productId: 'prod_1',
          productName: 'Item 1',
          quantity: 1,
          unitPrice: 980,
        ),
      ],
      advancePaid: 0,
      note: 'Note for visuals',
    );
    fakeRepo.orders.add(order);

    final vm = OrderViewModel(orderRepository: fakeRepo);
    await vm.loadOrders();

    // Set screen size to narrow mobile (360x700) matching screenshot
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ur'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          AppStrings.updateLocale(AppLocalizations.of(context));
          return child!;
        },
        home: Scaffold(
          body: OrdersView(viewModel: vm),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Expect zero layout overflow exceptions
    expect(tester.takeException(), isNull);

    // Verify key action elements are found and visible
    expect(find.text(order.partyName), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
