import 'package:flutter/material.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/ui/customers/customers_view.dart';
import 'package:katha_management/ui/dashboard/dashboard_view.dart';
import 'package:katha_management/ui/features/add_party/add_party_view.dart';
import 'package:katha_management/ui/orders/orders_view.dart';

class NavigationBarView extends StatefulWidget {
  static const String routeName = '/navigation-bar-view';
  static Route route() {
    return MaterialPageRoute(
      builder: (context) => const NavigationBarView(),
      settings: const RouteSettings(name: routeName),
    );
  }

  const NavigationBarView({super.key});

  @override
  State<NavigationBarView> createState() => _NavigationBarViewState();
}

class _NavigationBarViewState extends State<NavigationBarView> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    if (index == 3) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AddPartyView.routeName,
        (route) => false,
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  static const List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: AppStrings.navDashboard,
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      label: AppStrings.navOrders,
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: AppStrings.navCustomers,
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_add_alt_1_outlined),
      label: AppStrings.quickActionAddParty,
    ),
  ];

  static final List<WidgetBuilder> _pageBuilders = [
    (_) => const DashboardView(),
    (_) => const OrdersView(),
    (_) => const CustomersView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (final builder in _pageBuilders) Builder(builder: builder),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.accent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: _items,
      ),
    );
  }
}
