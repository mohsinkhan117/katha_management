import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/core/utils/app_dialogs/collect_payment_sheet.dart';
import 'package:katha_management/core/widgets/glass_card.dart';
import 'package:katha_management/ui/features/new_order/new_order_view.dart';
import 'package:katha_management/ui/orders/order_view_model.dart';
import 'package:provider/provider.dart';

class OrdersView extends StatelessWidget {
  static const String routeName = '/orders-view';
  static Route route() {
    return MaterialPageRoute(
      builder: (context) => const OrdersView(),
      settings: const RouteSettings(name: routeName),
    );
  }

  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderViewModel(),
      child: const _OrdersViewBody(),
    );
  }
}

class _OrdersViewBody extends StatelessWidget {
  const _OrdersViewBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppStrings.ordersTitle),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.08)
                    : AppColors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.glassBorderColor(isDark),
                  width: 1,
                ),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.16)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: AppColors.white,
                unselectedLabelColor: isDark
                    ? AppColors.grey
                    : AppColors.textSecondary,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.tabPending),
                        if (vm.pendingCount > 0) ...[
                          const SizedBox(width: AppSizes.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${vm.pendingCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.tabDone),
                        if (vm.doneCount > 0) ...[
                          const SizedBox(width: AppSizes.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${vm.doneCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: AmbientScaffoldBackground(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 22),
                    hintText: AppStrings.searchOrdersHint,
                  ),
                  onChanged: (value) =>
                      context.read<OrderViewModel>().setSearchQuery(value),
                ),
              ),
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vm.errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    _OrdersList(
                      orders: vm.pendingOrders,
                      emptyMessage: AppStrings.noPendingOrders,
                      isLoading: vm.isLoading,
                    ),
                    _OrdersList(
                      orders: vm.doneOrders,
                      emptyMessage: AppStrings.noDoneOrders,
                      isLoading: vm.isLoading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.pushNamed(context, NewOrderView.routeName);
            if (context.mounted) {
              context.read<OrderViewModel>().refresh();
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add),
          label: Text(AppStrings.newOrderButton),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.emptyMessage,
    required this.isLoading,
  });

  final List<OrderModel> orders;
  final String emptyMessage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<OrderViewModel>().refresh(),
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Text(
                  emptyMessage,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<OrderViewModel>().refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: AppSizes.md,
          right: AppSizes.md,
          bottom: 80,
        ),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _OrderCard(order: orders[index]);
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.order});
  final OrderModel order;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isExpanded = false;

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return AppColors.secondary;
      case OrderStatus.delivered:
        return AppColors.warning;
      case OrderStatus.paid:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusColor = _getStatusColor(order.status);
    final vm = context.read<OrderViewModel>();

    return GlassCard(
      borderRadius: 20,
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Party Name & Status Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.partyName,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeMd,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (order.partyPhone != null &&
                        order.partyPhone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        order.partyPhone!,
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xs + 2,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color:
                          order.advancePaid >= order.totalAmount &&
                              order.totalAmount > 0
                          ? AppColors.success.withValues(alpha: 0.12)
                          : (order.advancePaid > 0
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.grey.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadiusSm,
                      ),
                    ),
                    child: Text(
                      order.advancePaid >= order.totalAmount &&
                              order.totalAmount > 0
                          ? AppStrings.paymentStatusPaid
                          : (order.advancePaid > 0
                                ? 'Adv: Rs ${order.advancePaid.toStringAsFixed(0)}'
                                : AppStrings.paymentStatusUnpaid),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            order.advancePaid >= order.totalAmount &&
                                order.totalAmount > 0
                            ? AppColors.success
                            : (order.advancePaid > 0
                                  ? AppColors.primary
                                  : AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadiusSm,
                      ),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      order.status.label,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: AppSizes.spaceBtwItems),

          // Details: Timestamps, expected delivery & items summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppStrings.orderedPrefix}${_formatDate(order.orderDate)}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppStrings.updatedPrefix}${_formatDateTime(order.updatedAt)}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (order.expectedDeliveryDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${AppStrings.deliveryByPrefix}${_formatDate(order.expectedDeliveryDate!)}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${order.itemCount} ${order.itemCount == 1 ? AppStrings.itemSingular : AppStrings.itemsPlural}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs ${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeLg,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (order.advancePaid > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Due: Rs ${order.balanceDue.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: order.balanceDue > 0
                            ? AppColors.tetraColor
                            : AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              '${AppStrings.note}: ${order.note}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSm,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // Expandable Items List
          if (_isExpanded) ...[
            const Divider(height: AppSizes.spaceBtwItems),
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.productName}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      'Rs ${item.subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: AppSizes.sm),

          // Action Buttons
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded
                            ? AppStrings.hideItems
                            : AppStrings.viewItems,
                        style: const TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: AppSizes.iconSm,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (!order.status.isTerminal) ...[
                if (order.balanceDue > 0) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.payments_outlined, size: 14),
                    label: Text(AppStrings.collectAdvancePayment),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: AppSizes.xs,
                      ),
                      minimumSize: const Size(60, 32),
                    ),
                    onPressed: () async {
                      final collected = await showCollectPaymentSheet(
                        context,
                        partyId: order.partyId,
                        partyName: order.partyName,
                        partyPhone: order.partyPhone,
                        suggestedAmount: order.balanceDue,
                        orderId: order.id,
                      );
                      if (collected == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.paymentCollectedSuccess),
                          ),
                        );
                        vm.refresh();
                      }
                    },
                  ),
                  const SizedBox(width: AppSizes.xs),
                ],
                if (order.status == OrderStatus.placed) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: AppSizes.iconSm,
                      color: AppColors.primary,
                    ),
                    tooltip: AppStrings.editOrderTitle,
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        NewOrderView.route(orderToEdit: order),
                      );
                      if (updated == true && context.mounted) {
                        vm.refresh();
                      }
                    },
                  ),
                  const SizedBox(width: AppSizes.xs),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: AppSizes.iconSm,
                      color: AppColors.error,
                    ),
                    tooltip: AppStrings.deleteOrderButton,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(AppStrings.deleteOrderTitle),
                          content: Text(AppStrings.deleteOrderMessage),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(AppStrings.no),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: Text(AppStrings.deleteOrderButton),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final deleted = await vm.deleteOrder(order.id);
                        if (deleted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.orderDeletedSuccess),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: AppSizes.xs),
                ] else ...[
                  IconButton(
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: AppSizes.iconSm,
                      color: AppColors.error,
                    ),
                    tooltip: AppStrings.cancelOrderTooltip,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(AppStrings.cancelOrderTitle),
                          content: Text(AppStrings.cancelOrderMessage),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(AppStrings.no),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(AppStrings.yesCancel),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await vm.cancelOrder(order.id);
                      }
                    },
                  ),
                  const SizedBox(width: AppSizes.xs),
                ],
                ElevatedButton(
                  onPressed: () async {
                    final nextStatus = order.status.next;
                    final success = await vm.advanceStatus(order);
                    if (success &&
                        nextStatus == OrderStatus.paid &&
                        context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppStrings.orderPaidSuccess)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: order.status == OrderStatus.placed
                        ? AppColors.warning
                        : AppColors.success,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: AppSizes.xs,
                    ),
                    minimumSize: const Size(80, 32),
                  ),
                  child: Text(
                    'Mark ${order.status.next?.label ?? 'Done'}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      AppSizes.borderRadiusSm,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        order.status == OrderStatus.paid
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        size: AppSizes.iconSm,
                        color: statusColor,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        order.status.label,
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
