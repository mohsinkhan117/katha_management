// lib/ui/dashboard/dashboard_view.dart

import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: Consumer<DashboardViewmodel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.totalPartiesCount == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                if (vm.errorMessage != null) ...[
                  _ErrorBanner(message: vm.errorMessage!),
                  const SizedBox(height: AppSizes.spaceBtwSections),
                ],
                _SummaryCards(vm: vm),
                const SizedBox(height: AppSizes.spaceBtwSections),
                const _QuickActions(),
                const SizedBox(height: AppSizes.spaceBtwSections),
                const _SectionHeader(title: 'Top Pending Parties'),
                const SizedBox(height: AppSizes.spaceBtwItems),
                _PendingPartiesList(parties: vm.topPendingParties),
                const SizedBox(height: AppSizes.spaceBtwSections),
                const _SectionHeader(title: 'Recent Activity'),
                const SizedBox(height: AppSizes.spaceBtwItems),
                _RecentActivityList(items: vm.recentActivity),
                const SizedBox(height: AppSizes.spaceBtwSections),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.vm});

  final DashboardViewmodel vm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: _SummaryLargeCard(
              label: "Today's Sales",
              amount: vm.todaySales,
              icon: Icons.trending_up_rounded,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: AppSizes.sm),

          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: _SummarySmallCard(
                    label: "Today's Collection",
                    amount: vm.todayCollection,
                    icon: Icons.savings_outlined,
                    color: AppColors.success,
                  ),
                ),

                const SizedBox(height: AppSizes.sm),

                Expanded(
                  child: _SummarySmallCard(
                    label: 'Receivables',
                    amount: vm.totalReceivables,
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.tetraColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLargeCard extends StatelessWidget {
  const _SummaryLargeCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        color: color.withValues(alpha: 0.3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: AppSizes.iconMd),

          const SizedBox(height: AppSizes.sm),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Rs ${_formatAmount(amount)}',
              style: TextStyle(
                fontSize: AppSizes.fontSizeLg + 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),

          const SizedBox(height: AppSizes.md),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppSizes.fontSizeMd, color: color),
          ),
        ],
      ),
    );
  }
}

class _SummarySmallCard extends StatelessWidget {
  const _SummarySmallCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        color: color.withValues(alpha: 0.3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSizes.iconMd),

          const SizedBox(height: AppSizes.xs),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Rs ${_formatAmount(amount)}',
              style: TextStyle(
                fontSize: AppSizes.fontSizeMd,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: AppSizes.fontSizeSm, color: color),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.point_of_sale_outlined,
        'New Sale',
        () async {
          await Navigator.pushNamed(context, NewSaleView.routeName);
          if (context.mounted) {
            context.read<DashboardViewmodel>().refresh();
          }
        },
      ),
      (
        Icons.receipt_long_outlined,
        'New Order',
        () async {
          await Navigator.pushNamed(context, NewOrderView.routeName);
          if (context.mounted) {
            context.read<DashboardViewmodel>().refresh();
          }
        },
      ),
      (
        Icons.payments_outlined,
        'Add Payment',
        () async {
          await Navigator.pushNamed(context, PaymentView.routeName);
          if (context.mounted) {
            context.read<DashboardViewmodel>().refresh();
          }
        },
      ),
      (
        Icons.person_add_alt_outlined,
        'Add Party',
        () async {
          await Navigator.pushNamed(context, AddPartyView.routeName);
          if (context.mounted) {
            context.read<DashboardViewmodel>().refresh();
          }
        },
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions
          .map(
            (action) => _QuickActionButton(
              icon: action.$1,
              label: action.$2,
              onPressed: action.$3,
            ),
          )
          .toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              gradient: AppColors.primaryLinerGradient,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            ),
            child: Icon(
              icon,
              color: AppColors.textWhite,
              size: AppSizes.iconMd,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSm,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppSizes.fontSizeLg,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PendingPartiesList extends StatelessWidget {
  const _PendingPartiesList({required this.parties});
  final List<PartyBalanceSummary> parties;

  @override
  Widget build(BuildContext context) {
    if (parties.isEmpty) {
      return const Text(
        'No pending balances',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: parties
          .map(
            (party) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: _PendingPartyTile(party: party),
            ),
          )
          .toList(),
    );
  }
}

class _PendingPartyTile extends StatelessWidget {
  const _PendingPartyTile({required this.party});
  final PartyBalanceSummary party;

  @override
  Widget build(BuildContext context) {
    final days = party.daysSinceOldestDue;
    final isOverdue = days != null && days > 7;

    return ListTile(
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.lightContainer,
        child: Text(
          party.partyName.isNotEmpty ? party.partyName[0] : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        party.partyName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        party.partyPhone ?? 'No phone on file',
        style: const TextStyle(
          fontSize: AppSizes.fontSizeSm,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Rs ${party.balanceDue.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.tetraColor,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            days != null ? '${days}d overdue' : 'Opening balance',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSm,
              color: isOverdue ? AppColors.error : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.items});
  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'No recent activity',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: _ActivityTile(item: item),
            ),
          )
          .toList(),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});
  final ActivityItem item;

  (IconData, Color, String) get _typeMeta {
    switch (item.type) {
      case ActivityType.sale:
        return (Icons.arrow_upward_rounded, AppColors.primary, 'Sale');
      case ActivityType.payment:
        return (Icons.arrow_downward_rounded, AppColors.success, 'Payment');
      case ActivityType.order:
        return (
          Icons.receipt_long_outlined,
          AppColors.secondary,
          'Order Placed',
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
    final (icon, color, label) = _typeMeta;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: AppSizes.iconSm),
      ),
      title: Text(
        item.partyName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '$label • ${_formatTime(item.date)}',
        style: const TextStyle(
          fontSize: AppSizes.fontSizeSm,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Text(
        'Rs ${item.amount.toStringAsFixed(0)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: item.type == ActivityType.payment
              ? AppColors.success
              : AppColors.textPrimary,
        ),
      ),
    );
  }
}
