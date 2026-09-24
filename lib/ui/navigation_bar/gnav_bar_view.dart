import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/ui/products/product_list_view.dart';
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
      builder: (context) => const GnavBar(),
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
    (_) => const ProductListView(),
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final isVeryCompact = screenWidth < 340;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isVeryCompact ? 6 : (isCompact ? 10 : 16),
            vertical: 8,
          ),
          child: GNav(
            rippleColor: Colors.grey[300]!,
            hoverColor: Colors.grey[100]!,
            gap: isVeryCompact ? 3 : (isCompact ? 5 : 8),
            activeColor: AppColors.primary,
            iconSize: isVeryCompact ? 18 : (isCompact ? 20 : 22),
            textStyle: TextStyle(
              fontSize: isVeryCompact ? 11 : (isCompact ? 12 : 13),
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isVeryCompact ? 8 : (isCompact ? 10 : 14),
              vertical: isVeryCompact ? 6 : 8,
            ),
            duration: const Duration(milliseconds: 300),
            tabBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
            color: AppColors.textSecondary,
            selectedIndex: selectedIndex,
            onTabChange: onTabChange,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            tabs: [
              GButton(
                icon: Icons.dashboard_outlined,
                text: isCompact ? AppStrings.navHome : AppStrings.navDashboard,
              ),
              const GButton(
                icon: Icons.receipt_long_outlined,
                text: AppStrings.navOrders,
              ),
              GButton(
                icon: Icons.people_outline,
                text: isCompact
                    ? AppStrings.navParties
                    : AppStrings.navCustomers,
              ),
              const GButton(
                icon: Icons.inventory_2_outlined,
                text: AppStrings.navProducts,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
