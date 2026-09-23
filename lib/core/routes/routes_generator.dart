// lib/core/routes/routes_generator.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/product/product_model.dart';
import 'package:katha_management/ui/customers/customers_view.dart';
import 'package:katha_management/ui/features/add_party/add_party_view.dart';
import 'package:katha_management/ui/features/add_payment/payment_view.dart';
import 'package:katha_management/ui/features/add_product/add_product_view.dart';
import 'package:katha_management/ui/dashboard/dashboard_view.dart';
import 'package:katha_management/ui/navigation_bar/gnav_bar_view.dart';
import 'package:katha_management/ui/features/new_order/new_order_view.dart';
import 'package:katha_management/ui/features/new_sale/new_sale_view.dart';
import 'package:katha_management/ui/orders/orders_view.dart';
import 'package:katha_management/ui/party_history/party_history_view.dart';
import 'package:katha_management/ui/products/product_list_view.dart';
import 'package:katha_management/ui/settings_view/settings_view.dart';

class RouterGenerator {
  static Route onGenerateRoute(RouteSettings settings) {
    debugPrint("Navigating to: ${settings.name}");

    switch (settings.name) {
      // ======================================================
      // Core
      // ======================================================
      case GnavBar.routeName:
        return GnavBar.route();

      case DashboardView.routeName:
        return DashboardView.route();

      case CustomersView.routeName:
        return CustomersView.route();

      case PartyHistoryView.routeName:
        final partyId = (settings.arguments is String)
            ? settings.arguments as String
            : '';
        return PartyHistoryView.route(partyId: partyId);

      case OrdersView.routeName:
        return OrdersView.route();

      case ProductListView.routeName:
        return ProductListView.route();

      case NewSaleView.routeName:
        final partyId = settings.arguments as String?;
        return NewSaleView.route(partyId: partyId);

      case NewOrderView.routeName:
        final partyId = settings.arguments as String?;
        return NewOrderView.route(partyId: partyId);

      case PaymentView.routeName:
        final partyId = settings.arguments as String?;
        return PaymentView.route(partyId: partyId);

      case AddPartyView.routeName:
        return AddPartyView.route();

      case AddProductView.routeName:
        final existingProduct = settings.arguments as ProductModel?;
        return AddProductView.route(existingProduct: existingProduct);

      case SettingsView.routeName:
        return SettingsView.route();

      default:
        return _errorRoute();
    }
  }

  static Route _errorRoute() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: '/error'),
      builder: (_) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 100,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "The page you're looking for doesn't exist or is under construction.",
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
