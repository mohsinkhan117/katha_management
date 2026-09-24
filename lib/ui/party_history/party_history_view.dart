// lib/ui/party_history/party_history_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/new_order/new_order_item_model.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/models/sale_item_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/core/utils/app_dialogs/collect_payment_sheet.dart';
import 'package:katha_management/ui/features/add_payment/payment_view.dart';
import 'package:katha_management/ui/features/new_order/new_order_view.dart';
import 'package:katha_management/ui/features/new_sale/new_sale_view.dart';
import 'package:provider/provider.dart';

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
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          vm.party?.name ?? AppStrings.partyHistoryTitle,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (vm.isGeneratingPdf)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: AppStrings.exportPrintPdfTooltip,
              onPressed: vm.party == null ? null : vm.exportPdf,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: AppStrings.sharePdfTooltip,
              onPressed: vm.party == null ? null : vm.sharePdf,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.refresh,
            onPressed: vm.isLoading ? null : vm.refresh,
          ),
        ],
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, PartyHistoryViewModel vm) {
    if (vm.isLoading && vm.party == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null && vm.party == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSizes.sm),
              Text(
                vm.errorMessage!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.md),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                onPressed: vm.refresh,
                label: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          _BalanceHeader(vm: vm),
          const SizedBox(height: AppSizes.spaceBtwItems),
          _QuickActions(vm: vm),
          const SizedBox(height: AppSizes.spaceBtwItems),
          _FilterChips(vm: vm),
          const SizedBox(height: AppSizes.spaceBtwItems),
          _TimelineList(vm: vm),
        ],
      ),
    );
  }
}

/// Header containing Party info, Balance Due, and 4-metric overview grid
class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.vm});
  final PartyHistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final balance = vm.balance;
    final party = vm.party;
    final due = balance?.balanceDue ?? 0.0;

    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
        side: const BorderSide(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Party Info Bar
            if (party != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      party.name.isNotEmpty ? party.name[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          party.name,
                          style: const TextStyle(
                            fontSize: AppSizes.fontSizeLg,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (party.phone != null && party.phone!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    party.phone!,
                                    style: const TextStyle(
                                      fontSize: AppSizes.fontSizeSm,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  // Current Net Balance Badge & Collect Payment
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        AppStrings.netBalanceLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppStrings.currencyPrefix}${due.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeMd + 1,
                          fontWeight: FontWeight.bold,
                          color: due > 0
                              ? AppColors.tetraColor
                              : AppColors.success,
                        ),
                      ),
                      if (due > 0) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
                            final collected = await showCollectPaymentSheet(
                              context,
                              partyId: party.id,
                              partyName: party.name,
                              partyPhone: party.phone,
                              suggestedAmount: due,
                            );
                            if (collected == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    AppStrings.paymentCollectedSuccess,
                                  ),
                                ),
                              );
                              vm.load();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  AppStrings.actionPay,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Divider(height: AppSizes.lg),
            ],

            // Statistics 2x2 Grid (Total Sales, Payments, Balance, Orders)
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: AppStrings.totalSalesStat,
                    value:
                        '${AppStrings.currencyPrefix}${vm.totalSalesAmount.toStringAsFixed(0)}',
                    icon: Icons.point_of_sale_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _StatCard(
                    title: AppStrings.paymentsStat,
                    value:
                        '${AppStrings.currencyPrefix}${vm.totalPaymentsAmount.toStringAsFixed(0)}',
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: AppStrings.balanceDueStat,
                    value:
                        '${AppStrings.currencyPrefix}${due.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: due > 0 ? AppColors.tetraColor : AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: _StatCard(
                    title: '${AppStrings.ordersStat} (${vm.totalOrdersCount})',
                    value: '${vm.pendingOrdersCount} ${AppStrings.tabPending}',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),

            if (balance?.daysSinceOldestDue != null) ...[
              const SizedBox(height: AppSizes.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 15,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Expanded(
                      child: Text(
                        '${balance!.daysSinceOldestDue} ${AppStrings.daysSinceOldestUnpaidSale}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSm,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.vm});
  final PartyHistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.point_of_sale_outlined, size: 18),
                label: const Text(
                  AppStrings.actionSale,
                  style: TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
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
            const SizedBox(width: AppSizes.xs),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text(
                  AppStrings.actionOrder,
                  style: TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
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
            const SizedBox(width: AppSizes.xs),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text(
                  AppStrings.actionPay,
                  style: TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
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
        ),
        const SizedBox(height: AppSizes.xs),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text(AppStrings.exportPrintPdfTooltip),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: vm.isGeneratingPdf || vm.party == null
                ? null
                : vm.exportPdf,
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
    final options = {
      PartyHistoryFilter.all: '${AppStrings.filterAll} (${vm.timeline.length})',
      PartyHistoryFilter.orders:
          '${AppStrings.filterOrders} (${vm.orders.length})',
      PartyHistoryFilter.sales:
          '${AppStrings.filterSales} (${vm.sales.length})',
      PartyHistoryFilter.payments:
          '${AppStrings.filterPayments} (${vm.payments.length})',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = vm.filter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.xs),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
              ),
              onSelected: (_) =>
                  context.read<PartyHistoryViewModel>().setFilter(entry.key),
            ),
          );
        }).toList(),
      ),
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
          child: Column(
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 40,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppSizes.xs),
              Text(
                AppStrings.noTransactionsRecorded,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: _TimelineTile(entry: entry, vm: vm),
            ),
          )
          .toList(),
    );
  }
}

/// Expandable accordion dropdown tile for Orders, Sales, and Payments
class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry, required this.vm});
  final PartyHistoryEntry entry;
  final PartyHistoryViewModel vm;

  static final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');

  (IconData, Color) get _meta {
    switch (entry.type) {
      case PartyHistoryEntryType.sale:
        return (Icons.point_of_sale_outlined, AppColors.primary);
      case PartyHistoryEntryType.order:
        return (Icons.receipt_long_outlined, AppColors.secondary);
      case PartyHistoryEntryType.payment:
        return (Icons.payments_outlined, AppColors.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _meta;

    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
        side: const BorderSide(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSizes.md,
            0,
            AppSizes.md,
            AppSizes.md,
          ),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: AppSizes.iconSm),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppSizes.fontSizeMd,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                '${AppStrings.currencyPrefix}${entry.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppSizes.fontSizeMd,
                  color: entry.type == PartyHistoryEntryType.payment
                      ? AppColors.success
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${entry.subtitle != null ? '${entry.subtitle} • ' : ''}${_dateFormat.format(entry.date)}',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSm,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            const Divider(height: AppSizes.md),
            if (entry.order != null) _buildOrderDetails(context, entry.order!),
            if (entry.sale != null) _buildSaleDetails(context, entry.sale!),
            if (entry.payment != null) _buildPaymentDetails(entry.payment!),
          ],
        ),
      ),
    );
  }

  // ─── Order Details Dropdown ─────────────────────────────────────────
  Widget _buildOrderDetails(BuildContext context, OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status & Delivery Dates
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '${AppStrings.status}: ',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                _OrderStatusBadge(status: order.status),
              ],
            ),
            // Status Update Dropdown Menu
            PopupMenuButton<OrderStatus>(
              tooltip: AppStrings.changeStatusTooltip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderPrimary),
                  borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.update,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
              onSelected: (newStatus) {
                vm.updateOrderStatus(order.id, newStatus);
              },
              itemBuilder: (context) => OrderStatus.values.map((status) {
                return PopupMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Icon(
                        status == order.status
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 16,
                        color: status == order.status
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(status.label),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),

        if (order.expectedDeliveryDate != null) ...[
          Row(
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  '${AppStrings.expectedDeliveryPrefix}${_dateFormat.format(order.expectedDeliveryDate!)}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSm,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
        ],

        // Order Items List
        const Text(
          AppStrings.orderItemsLabel,
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.xs),

        Container(
          decoration: BoxDecoration(
            color: AppColors.lightGrey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
          ),
          child: Column(
            children: order.items
                .map((item) => _buildOrderItemRow(item))
                .toList(),
          ),
        ),

        if (order.note != null && order.note!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSizes.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.notes_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  '${AppStrings.note}: ${order.note!}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSm,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Advance vs Balance Due & Collect Button
        const SizedBox(height: AppSizes.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.advancePrefix}${order.advancePaid.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  '${AppStrings.duePrefix}${order.balanceDue.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: order.balanceDue > 0
                        ? AppColors.tetraColor
                        : AppColors.success,
                  ),
                ),
              ],
            ),
            if (order.balanceDue > 0 && !order.status.isTerminal)
              ElevatedButton.icon(
                icon: const Icon(Icons.payments_outlined, size: 14),
                label: const Text(AppStrings.collectAdvancePayment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                ),
                onPressed: () async {
                  final collected = await showCollectPaymentSheet(
                    context,
                    partyId: vm.partyId,
                    partyName: vm.party?.name ?? order.partyName,
                    partyPhone: vm.party?.phone ?? order.partyPhone,
                    suggestedAmount: order.balanceDue,
                    orderId: order.id,
                  );
                  if (collected == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.paymentCollectedSuccess),
                      ),
                    );
                    vm.load();
                  }
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderItemRow(OrderItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} × ${AppStrings.currencyPrefix}${item.unitPrice.toStringAsFixed(0)}'
                  '${item.discount > 0 ? ' (-${AppStrings.currencyPrefix}${item.discount.toStringAsFixed(0)})' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${AppStrings.currencyPrefix}${item.subtotal.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSm,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sale Details Dropdown ──────────────────────────────────────────
  Widget _buildSaleDetails(BuildContext context, SaleModel sale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '${AppStrings.status}: ',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                _SaleStatusBadge(status: sale.status),
              ],
            ),
            Text(
              '${AppStrings.datePrefix}${_dateFormat.format(sale.saleDate)}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),

        // Items Breakdown
        if (sale.items.isNotEmpty) ...[
          const Text(
            AppStrings.saleItemsLabel,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSm,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightGrey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
            ),
            child: Column(
              children: sale.items
                  .map((item) => _buildSaleItemRow(item))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
        ],

        // Financial Breakdown (Total, Paid, Balance Due)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppStrings.paidPrefix}${sale.paidAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            Text(
              '${AppStrings.duePrefix}${sale.balanceDue.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                fontWeight: FontWeight.bold,
                color: sale.balanceDue > 0
                    ? AppColors.tetraColor
                    : AppColors.success,
              ),
            ),
          ],
        ),

        if (sale.note != null && sale.note!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            '${AppStrings.note}: ${sale.note!}',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSm,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],

        // Collect Payment Button if Balance Due > 0
        if (sale.balanceDue > 0) ...[
          const SizedBox(height: AppSizes.sm),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payments_outlined, size: 16),
              label: const Text(AppStrings.collectPayment),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.xs,
                ),
              ),
              onPressed: () async {
                final collected = await showCollectPaymentSheet(
                  context,
                  partyId: vm.partyId,
                  partyName: vm.party?.name ?? sale.partyName,
                  partyPhone: vm.party?.phone ?? sale.partyPhone,
                  suggestedAmount: sale.balanceDue,
                  saleId: sale.id,
                );
                if (collected == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.paymentCollectedSuccess),
                    ),
                  );
                  vm.load();
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSaleItemRow(SaleItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} × ${AppStrings.currencyPrefix}${item.unitPrice.toStringAsFixed(0)}'
                  '${item.discount > 0 ? ' (-${AppStrings.currencyPrefix}${item.discount.toStringAsFixed(0)})' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${AppStrings.currencyPrefix}${item.subtotal.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSm,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Payment Details Dropdown ───────────────────────────────────────
  Widget _buildPaymentDetails(PaymentModel payment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppStrings.paymentModePrefix}${payment.mode.label}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${AppStrings.datePrefix}${_dateFormat.format(payment.paymentDate)}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (payment.note != null && payment.note!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            '${AppStrings.note}: ${payment.note!}',
            style: const TextStyle(
              fontSize: AppSizes.fontSizeSm,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});
  final OrderStatus status;

  Color get _color {
    switch (status) {
      case OrderStatus.placed:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.primary;
      case OrderStatus.dispatched:
        return AppColors.secondary;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _SaleStatusBadge extends StatelessWidget {
  const _SaleStatusBadge({required this.status});
  final SaleStatus status;

  Color get _color {
    switch (status) {
      case SaleStatus.paid:
        return AppColors.success;
      case SaleStatus.partial:
        return AppColors.warning;
      case SaleStatus.pending:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
