// lib/ui/navigation_bar/gnav_bar_view.dart

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/ui/customers/customers_view.dart';
import 'package:katha_management/ui/dashboard/dashboard_view.dart';
import 'package:katha_management/ui/orders/orders_view.dart';

import 'gnav_bar_view_model.dart';

/// The app's main navigation shell: owns which tab is selected,
/// renders that tab's page, and shows the bottom nav bar underneath.
///
/// Self-contained — wraps its own `ChangeNotifierProvider`, so it can
/// be dropped in directly as the app's home widget (e.g. `home: const
/// GnavBar()` in `MaterialApp`, or pushed via `GnavBar.route()`) with
/// no setup required anywhere else.
class GnavBar extends StatelessWidget {
  const GnavBar({super.key});

  static const String routeName = '/gnav-bar-view';
  static Route route() {
    return MaterialPageRoute(
      // builder: (context) => ChangeNotifierProvider(create:(_)=> GnavBarViewModel(),child: _GnavBarBody(),),
      builder: (context) => GnavBar(),

      settings: const RouteSettings(name: routeName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GnavBarViewModel(),
      child: const _GnavBarBody(),
    );
  }
}

class _GnavBarBody extends StatefulWidget {
  const _GnavBarBody();

  @override
  State<_GnavBarBody> createState() => _GnavBarBodyState();
}

class _GnavBarBodyState extends State<_GnavBarBody> {
  final Set<int> _visitedIndices = {0};

  static final List<WidgetBuilder> _pageBuilders = [
    (_) => const DashboardView(),
    (_) => const OrdersView(),
    (_) => const CustomersView(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = context.watch<GnavBarViewModel>().selectedIndex;
    _visitedIndices.add(selectedIndex);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: List.generate(_pageBuilders.length, (index) {
          if (!_visitedIndices.contains(index)) {
            return const SizedBox.shrink();
          }
          return _pageBuilders[index](context);
        }),
      ),
      bottomNavigationBar: _NavBar(
        selectedIndex: selectedIndex,
        onTabChange: context.read<GnavBarViewModel>().setSelectedIndex,
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.selectedIndex, required this.onTabChange});

  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      // decoration: BoxDecoration(
      //   color: AppColors.accent,
      //   boxShadow: [
      //     BoxShadow(blurRadius: 20, color: Colors.black.withValues(alpha: 0.1)),
      //   ],
      // ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: GNav(
            rippleColor: Colors.grey[300]!,
            hoverColor: Colors.grey[100]!,
            gap: 8,
            activeColor: AppColors.primary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: Colors.grey[100]!,
            color: AppColors.textSecondary,
            selectedIndex: selectedIndex,
            onTabChange: onTabChange,
            tabs: const [
              GButton(icon: Icons.dashboard, text: 'Dashboard'),
              GButton(icon: Icons.receipt, text: 'Orders'),
              GButton(icon: Icons.people, text: 'Customers'),
            ],
          ),
        ),
      ),
    );
  }
}
