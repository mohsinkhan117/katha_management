import 'package:flutter/material.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/ui/add_party/add_party_view.dart';
import 'package:katha_management/ui/add_payment/payment_view.dart';
import 'package:katha_management/ui/new_order/new_order_view.dart';
import 'package:katha_management/ui/new_sale/new_sale_view.dart';

class NavigationBarView extends StatefulWidget {
  static const String routeName = '/navigation-bar-view';
  static Route route() {
    return MaterialPageRoute(
      builder: (context) => NavigationBarView(),
      settings: RouteSettings(name: routeName),
    );
  }

  const NavigationBarView({super.key});

  @override
  State<NavigationBarView> createState() => _NavigationBarViewState();
}

int selectedIdx = 0;

class _NavigationBarViewState extends State<NavigationBarView> {
  @override
  Widget build(BuildContext context) {
    void navigatBottomBar(int index) {
      setState(() {
        selectedIdx = index;
      });
    }

    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.outbox), label: 'outbox'),
      BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'payment'),
      BottomNavigationBarItem(icon: Icon(Icons.party_mode), label: 'party'),
    ];

    final List<Widget> pages = [
      NewSaleView(),
      NewOrderView(),
      PaymentView(),
      AddPartyView(),
    ];
    return Scaffold(
      body: pages[selectedIdx],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.accent,
        selectedItemColor: AppColors.primary,
        onTap: navigatBottomBar,
        currentIndex: selectedIdx,
        items: items,
      ),
    );
  }
}
