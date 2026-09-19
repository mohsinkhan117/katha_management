// lib/ui/party_history/party_history_view.dart

import 'package:flutter/material.dart';
import 'package:katha_management/ui/features/add_payment/payment_view.dart';
import 'package:katha_management/ui/features/new_order/new_order_view.dart';
import 'package:katha_management/ui/features/new_sale/new_sale_view.dart';
import 'package:provider/provider.dart';

import '../../core/constants/sizes/sizes.dart';
import '../../core/theme/app_colors/app_colors.dart';
import 'party_history_view_model.dart';

class PartyHistoryView extends StatelessWidget {
  static const String routeName = '/party-history-view';
  static Route route({required String partyId}) {
    return MaterialPageRoute(
      builder: (context) => PartyHistoryView(partyId: partyId),
      settings: RouteSettings(name: routeName, arguments: partyId),
    );
  }

  const PartyHistoryView({super.key, required this.partyId});
  final String partyId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PartyHistoryViewModel(partyId: partyId),
      child: const _PartyHistoryViewBody(),
    );
  }
}

class _PartyHistoryViewBody extends StatelessWidget {
  const _PartyHistoryViewBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PartyHistoryViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(vm.party?.name ?? 'Party History')),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, PartyHistoryViewModel vm) {
    if (vm.isLoading && vm.party == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null && vm.party == null) {
      return Center(
        child: Text(
          vm.errorMessage!,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          _BalanceHeader(vm: vm),
          const SizedBox(height: AppSizes.spaceBtwSections),
          _QuickActions(vm: vm),
          const SizedBox(height: AppSizes.spaceBtwSections),
          _FilterChips(vm: vm),
          const SizedBox(height: AppSizes.spaceBtwItems),
          _TimelineList(vm: vm),
        ],
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.vm});
  final PartyHistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final balance = vm.balance;
    final party = vm.party;

    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (party?.phone != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: AppSizes.iconSm,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    party!.phone!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Balance',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeMd,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  balance != null
                      ? 'Rs ${balance.balanceDue.toStringAsFixed(0)}'
                      : '—',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLg,
                    fontWeight: FontWeight.bold,
                    color: (balance?.balanceDue ?? 0) > 0
                        ? AppColors.tetraColor
                        : AppColors.success,
                  ),
                ),
              ],
            ),
            if (balance?.daysSinceOldestDue != null) ...[
              const SizedBox(height: AppSizes.xs),
              Text(
                '${balance!.daysSinceOldestDue}d since oldest unpaid sale',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeSm,
                  color: AppColors.warning,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.vm});
  final PartyHistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(
              Icons.point_of_sale_outlined,
              size: AppSizes.iconSm,
            ),
            label: const Text('New Sale'),
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                NewSaleView.routeName,
                arguments: vm.partyId,
              );
              if (context.mounted) vm.refresh();
            },
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(
              Icons.receipt_long_outlined,
              size: AppSizes.iconSm,
            ),
            label: const Text('New Order'),
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                NewOrderView.routeName,
                arguments: vm.partyId,
              );
              if (context.mounted) vm.refresh();
            },
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.payments_outlined, size: AppSizes.iconSm),
            label: const Text('Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
            ),
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                PaymentView.routeName,
                arguments: vm.partyId,
              );
              if (context.mounted) vm.refresh();
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.vm});
  final PartyHistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    const options = {
      PartyHistoryFilter.all: 'All',
      PartyHistoryFilter.sales: 'Sales',
      PartyHistoryFilter.orders: 'Orders',
      PartyHistoryFilter.payments: 'Payments',
    };

    return Wrap(
      spacing: AppSizes.sm,
      children: options.entries.map((entry) {
        final isSelected = vm.filter == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: isSelected,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
          ),
          onSelected: (_) =>
              context.read<PartyHistoryViewModel>().setFilter(entry.key),
        );
      }).toList(),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.vm});
  final PartyHistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final entries = vm.timeline;

    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
        child: Center(
          child: Text(
            'Nothing recorded yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(top: AppSizes.sm),
              child: _TimelineTile(entry: entry),
            ),
          )
          .toList(),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry});
  final PartyHistoryEntry entry;

  (IconData, Color) get _meta {
    switch (entry.type) {
      case PartyHistoryEntryType.sale:
        return (Icons.arrow_upward_rounded, AppColors.primary);
      case PartyHistoryEntryType.order:
        return (Icons.receipt_long_outlined, AppColors.secondary);
      case PartyHistoryEntryType.payment:
        return (Icons.arrow_downward_rounded, AppColors.success);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _meta;

    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: AppSizes.iconSm),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${entry.subtitle != null ? '${entry.subtitle} • ' : ''}${_formatDate(entry.date)}',
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Text(
          'Rs ${entry.amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: entry.type == PartyHistoryEntryType.payment
                ? AppColors.success
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
