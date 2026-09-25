// lib/ui/dashboard/dashboard_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/party_balance_summary.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/ui/dashboard/dashboard_view_model.dart';
import 'package:katha_management/ui/features/add_party/add_party_view.dart';
import 'package:katha_management/ui/features/add_payment/payment_view.dart';
import 'package:katha_management/ui/features/new_order/new_order_view.dart';
import 'package:katha_management/ui/features/new_sale/new_sale_view.dart';
import 'package:katha_management/ui/party_history/party_history_view.dart';
import 'package:katha_management/ui/settings_view/settings_view.dart';
import 'package:katha_management/core/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class DashboardView extends StatelessWidget {
  static const String routeName = '/dashboard-view';
  static Route route() {
    return MaterialPageRoute(
      builder: (context) => const DashboardView(),
      settings: const RouteSettings(name: routeName),
    );
  }

  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewmodel(),
      child: const _HomeViewBody(),
    );
  }
}

class _HomeViewBody extends StatelessWidget {
  const _HomeViewBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientScaffoldBackground(
        child: SafeArea(
          bottom: false,
          child: Consumer<DashboardViewmodel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.totalPartiesCount == 0) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: vm.refresh,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  children: [
                    // Top App Header
                    const _DashboardTopBar(),
                    const SizedBox(height: AppSizes.spaceBtwItems),

                    // Error Banner
                    if (vm.errorMessage != null) ...[
                      _ErrorBanner(message: vm.errorMessage!),
                      const SizedBox(height: AppSizes.spaceBtwItems),
                    ],

                    // Hero Financial Widget (iOS Large/Medium Widget)
                    _HeroReceivablesWidget(vm: vm),
                    const SizedBox(height: AppSizes.spaceBtwItems),

                    // 2x2 Bento Small Widgets (Today's Sales & Collection)
                    _BentoMetricsRow(vm: vm),
                    const SizedBox(height: AppSizes.spaceBtwItems),

                    // Quick Actions (iOS 4-Pod Action Widget)
                    const _QuickActionsWidget(),
                    const SizedBox(height: AppSizes.spaceBtwSections),

                    // Top Pending Parties (iOS Stacked List Widget)
                    _TopPendingPartiesWidget(parties: vm.topPendingParties),
                    const SizedBox(height: AppSizes.spaceBtwSections),

                    // Recent Activity (iOS Feed Widget)
                    _RecentActivityWidget(items: vm.recentActivity),
                    const SizedBox(height: AppSizes.spaceBtwSections),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Top Bar with Date Pill & Glass Settings ─────────────────────────────────
class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM').format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Glassy Date Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.08)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSm - 1,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.dashboardTitle,
              style: TextStyle(
                fontSize: AppSizes.fontSizeLg + 6,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),

        // Glassy Settings Button
        GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(10),
          onTap: () {
            Navigator.pushNamed(context, SettingsView.routeName);
          },
          child: Icon(
            Icons.settings_outlined,
            size: AppSizes.iconMd,
            color: isDark ? AppColors.textWhite : AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// ─── Hero Financial Widget (Large Bento Receivables Card) ────────────────────
class _HeroReceivablesWidget extends StatelessWidget {
  const _HeroReceivablesWidget({required this.vm});
  final DashboardViewmodel vm;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category icon & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.tetraColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.tetraColor,
                      size: AppSizes.iconSm + 2,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    AppStrings.receivables,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeMd,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tetraColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppStrings.currency,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tetraColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Large Metric Display
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${AppStrings.currencyPrefix}${vm.totalReceivables.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Divider Bar
          Container(
            height: 1,
            color: isDark
                ? AppColors.white.withValues(alpha: 0.08)
                : AppColors.borderSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSizes.md),

          // Mini Stats Sub-row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.todaysSales,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeSm - 1,
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${AppStrings.currencyPrefix}${vm.todaySales.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeSm,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textWhite
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 28,
                width: 1,
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.08)
                    : AppColors.borderSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.success,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.todaysCollection,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeSm - 1,
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${AppStrings.currencyPrefix}${vm.todayCollection.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeSm,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textWhite
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bento Metrics Row (Two Square iOS Widgets) ──────────────────────────────
class _BentoMetricsRow extends StatelessWidget {
  const _BentoMetricsRow({required this.vm});
  final DashboardViewmodel vm;

  String _formatAmount(double value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Widget 1: Today's Sales
        Expanded(
          child: GlassCard(
            borderRadius: 22,
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.primary,
                    size: AppSizes.iconMd - 2,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${AppStrings.currencyPrefix}${_formatAmount(vm.todaySales)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textWhite
                          : AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.todaysSales,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSm,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppSizes.sm),

        // Widget 2: Today's Collection
        Expanded(
          child: GlassCard(
            borderRadius: 22,
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    color: AppColors.success,
                    size: AppSizes.iconMd - 2,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${AppStrings.currencyPrefix}${_formatAmount(vm.todayCollection)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textWhite
                          : AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.todaysCollection,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSm,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Quick Actions (iPhone Style Action Pods Widget) ─────────────────────────
class _QuickActionsWidget extends StatelessWidget {
  const _QuickActionsWidget();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.point_of_sale_rounded,
        AppStrings.quickActionNewSale,
        AppColors.primary,
        () async {
          await Navigator.pushNamed(context, NewSaleView.routeName);
          if (context.mounted) {
            context.read<DashboardViewmodel>().refresh();
          }
        },
      ),
      (
        Icons.receipt_long_rounded,
        AppStrings.quickActionNewOrder,
        AppColors.secondary,
        () async {
          await Navigator.pushNamed(context, NewOrderView.routeName);
          if (context.mounted) {
            context.read<DashboardViewmodel>().refresh();
          }
        },
      ),
      (
        Icons.payments_rounded,
        AppStrings.quickActionAddPayment,
        AppColors.success,
        () async {
          await Navigator.pushNamed(context, PaymentView.routeName);
          if (context.mounted) {
            context.read<DashboardViewmodel>().refresh();
          }
        },
      ),
      (
        Icons.person_add_alt_1_rounded,
        AppStrings.quickActionAddParty,
        AppColors.accent,
        () async {
          await Navigator.pushNamed(context, AddPartyView.routeName);
          if (context.mounted) {
            context.read<DashboardViewmodel>().refresh();
          }
        },
      ),
    ];

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions
            .map(
              (act) => _GlassActionPod(
                icon: act.$1,
                label: act.$2,
                tintColor: act.$3,
                onTap: act.$4,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _GlassActionPod extends StatelessWidget {
  const _GlassActionPod({
    required this.icon,
    required this.label,
    required this.tintColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tintColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: tintColor.withValues(alpha: 0.15),
        highlightColor: tintColor.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: tintColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: tintColor.withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                ),
                child: Icon(icon, color: tintColor, size: AppSizes.iconMd),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSm - 1,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top Pending Parties (iOS Stack Widget) ──────────────────────────────────
class _TopPendingPartiesWidget extends StatelessWidget {
  const _TopPendingPartiesWidget({required this.parties});
  final List<PartyBalanceSummary> parties;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 24,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      AppStrings.topPendingParties,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMd,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textWhite
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (parties.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.white.withValues(alpha: 0.08)
                          : AppColors.borderSecondary.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${parties.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: isDark
                ? AppColors.white.withValues(alpha: 0.08)
                : AppColors.borderSecondary.withValues(alpha: 0.6),
          ),

          if (parties.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Center(
                child: Text(
                  AppStrings.noPendingBalances,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                    fontSize: AppSizes.fontSizeSm,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: parties.length,
              separatorBuilder: (_, _) => Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                height: 1,
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.05)
                    : AppColors.borderSecondary.withValues(alpha: 0.4),
              ),
              itemBuilder: (context, index) {
                final party = parties[index];
                return _PendingPartyTile(party: party);
              },
            ),
        ],
      ),
    );
  }
}

class _PendingPartyTile extends StatelessWidget {
  const _PendingPartyTile({required this.party});
  final PartyBalanceSummary party;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = party.daysSinceOldestDue;
    final isOverdue = days != null && days > 7;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(
            context,
            PartyHistoryView.routeName,
            arguments: party.partyId,
          );
          if (context.mounted) {
            context.read<DashboardViewmodel>().refresh();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm + 2,
          ),
          child: Row(
            children: [
              // Squircle Avatar
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.08)
                      : AppColors.lightContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.08)
                        : AppColors.borderSecondary.withValues(alpha: 0.6),
                  ),
                ),
                child: Center(
                  child: Text(
                    party.partyName.isNotEmpty ? party.partyName[0] : '?',
                    style: TextStyle(
                      color: isDark ? AppColors.accent : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.fontSizeMd,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.partyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: AppSizes.fontSizeMd - 1,
                        color: isDark
                            ? AppColors.textWhite
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      party.partyPhone ?? AppStrings.noPhoneOnFile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSm - 1,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing Due & Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${AppStrings.currencyPrefix}${party.balanceDue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: AppSizes.fontSizeMd - 1,
                      color: AppColors.tetraColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (isOverdue ? AppColors.error : AppColors.warning)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      days != null
                          ? '$days${AppStrings.daysOverdueSuffix}'
                          : AppStrings.openingBalanceLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? AppColors.error : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recent Activity (iOS Feed Widget) ───────────────────────────────────────
class _RecentActivityWidget extends StatelessWidget {
  const _RecentActivityWidget({required this.items});
  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 24,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      AppStrings.recentActivity,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMd,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textWhite
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: isDark
                ? AppColors.white.withValues(alpha: 0.08)
                : AppColors.borderSecondary.withValues(alpha: 0.6),
          ),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Center(
                child: Text(
                  AppStrings.noRecentActivity,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                    fontSize: AppSizes.fontSizeSm,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                height: 1,
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.05)
                    : AppColors.borderSecondary.withValues(alpha: 0.4),
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _ActivityTile(item: item);
              },
            ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});
  final ActivityItem item;

  (IconData, Color, String) get _typeMeta {
    switch (item.type) {
      case ActivityType.sale:
        return (
          Icons.arrow_upward_rounded,
          AppColors.primary,
          AppStrings.activityTypeSale,
        );
      case ActivityType.payment:
        return (
          Icons.arrow_downward_rounded,
          AppColors.success,
          AppStrings.activityTypePayment,
        );
      case ActivityType.order:
        return (
          Icons.receipt_long_rounded,
          AppColors.secondary,
          AppStrings.activityTypeOrder,
        );
    }
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, color, label) = _typeMeta;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      child: Row(
        children: [
          // Activity Squircle Icon
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: AppSizes.iconSm + 2),
          ),
          const SizedBox(width: AppSizes.sm),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.partyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppSizes.fontSizeMd - 1,
                    color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$label • ${_formatTime(item.date)}',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSm - 1,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '${AppStrings.currencyPrefix}${item.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: AppSizes.fontSizeMd - 1,
              color: item.type == ActivityType.payment
                  ? AppColors.success
                  : (isDark ? AppColors.textWhite : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error Banner ────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: AppSizes.iconSm,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
