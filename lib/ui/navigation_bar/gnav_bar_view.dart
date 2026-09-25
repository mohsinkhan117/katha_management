import 'dart:ui';
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
      extendBody: true,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final isVeryCompact = screenWidth < 340;

    final activeColor = isDark ? AppColors.accent : AppColors.primary;
    final tabBgColor = (isDark ? AppColors.accent : AppColors.primary)
        .withValues(alpha: isDark ? 0.16 : 0.10);
    final borderColor = AppColors.glassBorderColor(isDark);
    final shadowColor = AppColors.glassShadowColor(isDark);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.glassGradient(isDark),
            border: Border(top: BorderSide(color: borderColor, width: 1)),
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                color: shadowColor,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isVeryCompact ? 6 : (isCompact ? 10 : 16),
                vertical: 8,
              ),
              child: GNav(
                rippleColor: isDark
                    ? AppColors.white.withValues(alpha: 0.08)
                    : AppColors.primary.withValues(alpha: 0.08),
                hoverColor: isDark
                    ? AppColors.white.withValues(alpha: 0.04)
                    : AppColors.primary.withValues(alpha: 0.04),
                gap: isVeryCompact ? 3 : (isCompact ? 5 : 8),
                activeColor: activeColor,
                iconSize: isVeryCompact ? 18 : (isCompact ? 20 : 22),
                textStyle: TextStyle(
                  fontSize: isVeryCompact ? 11 : (isCompact ? 12 : 13),
                  fontWeight: FontWeight.w700,
                  color: activeColor,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isVeryCompact ? 8 : (isCompact ? 10 : 14),
                  vertical: isVeryCompact ? 6 : 8,
                ),
                duration: const Duration(milliseconds: 300),
                tabBackgroundColor: tabBgColor,
                color: isDark ? AppColors.grey : AppColors.textSecondary,
                selectedIndex: selectedIndex,
                onTabChange: onTabChange,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                tabs: [
                  GButton(
                    icon: Icons.dashboard_outlined,
                    text: isCompact
                        ? AppStrings.navHome
                        : AppStrings.navDashboard,
                  ),
                  GButton(
                    icon: Icons.receipt_long_outlined,
                    text: AppStrings.navOrders,
                  ),
                  GButton(
                    icon: Icons.people_outline,
                    text: isCompact
                        ? AppStrings.navParties
                        : AppStrings.navCustomers,
                  ),
                  GButton(
                    icon: Icons.inventory_2_outlined,
                    text: AppStrings.navProducts,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
