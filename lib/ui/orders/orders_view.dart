// lib/ui/orders/orders_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Orders'),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pending'),
                    if (vm.pendingCount > 0) ...[
                      const SizedBox(width: AppSizes.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${vm.pendingCount}',
                          style: const TextStyle(
                            fontSize: 12,
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
                    const Text('Done'),
                    if (vm.doneCount > 0) ...[
                      const SizedBox(width: AppSizes.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${vm.doneCount}',
                          style: const TextStyle(
                            fontSize: 12,
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search orders by party, item, or note...',
                ),
                onChanged: (value) =>
                    context.read<OrderViewModel>().setSearchQuery(value),
              ),
            ),
            if (vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _OrdersList(
                    orders: vm.pendingOrders,
                    emptyMessage: 'No pending orders',
                    isLoading: vm.isLoading,
                  ),
                  _OrdersList(
                    orders: vm.doneOrders,
                    emptyMessage: 'No completed/cancelled orders',
                    isLoading: vm.isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.pushNamed(context, NewOrderView.routeName);
            if (context.mounted) {
              context.read<OrderViewModel>().refresh();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('New Order'),
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
  bool _isConverting = false;

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return AppColors.secondary;
      case OrderStatus.confirmed:
        return AppColors.primary;
      case OrderStatus.dispatched:
        return AppColors.warning;
      case OrderStatus.delivered:
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

  Future<void> _handleConvertToSale(OrderModel order, OrderViewModel vm) async {
    // Local guard against a fast double-tap firing this twice before
    // the widget rebuilds — the real guard lives in the ViewModel
    // (`order.convertedSaleId`), this just avoids a redundant call.
    if (_isConverting) return;
    setState(() => _isConverting = true);

    final success = await vm.convertToSale(order);

    if (!mounted) return;
    setState(() => _isConverting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order converted to Sale invoice')),
      );
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusColor = _getStatusColor(order.status);
    final vm = context.read<OrderViewModel>();
    final alreadyConverted = order.convertedSaleId != null;

    return Card(
      elevation: AppSizes.cardElevation,
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
      ),
      child: Padding(
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
            const Divider(height: AppSizes.spaceBtwItems),

            // Details: Timestamps, expected delivery & items summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ordered: ${_formatDate(order.orderDate)}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Updated: ${_formatDateTime(order.updatedAt)}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (order.expectedDeliveryDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Delivery by: ${_formatDate(order.expectedDeliveryDate!)}',
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
                      '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
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
                  ],
                ),
              ],
            ),

            if (order.note != null && order.note!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.xs),
              Text(
                'Note: ${order.note}',
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
                          _isExpanded ? 'Hide items' : 'View items',
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
                  // "Convert to Sale" removed from here: converting an
                  // order to a sale only makes sense once it has
                  // actually been delivered. Cancel is the only
                  // action available before then.
                  IconButton(
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: AppSizes.iconSm,
                      color: AppColors.error,
                    ),
                    tooltip: 'Cancel order',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel Order?'),
                          content: const Text(
                            'Are you sure you want to cancel this order?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Yes, Cancel'),
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
                  ElevatedButton(
                    onPressed: () => vm.advanceStatus(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
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
                ] else if (order.status == OrderStatus.delivered) ...[
                  if (alreadyConverted)
                    // Once converted, this is the only state this
                    // order can ever show here again — no button,
                    // nothing tappable, just a fact about its history.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: AppSizes.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadiusSm,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: AppSizes.iconSm,
                            color: AppColors.success,
                          ),
                          SizedBox(width: AppSizes.xs),
                          Text(
                            'Converted to Sale',
                            style: TextStyle(
                              fontSize: AppSizes.fontSizeSm,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _isConverting
                          ? null
                          : () => _handleConvertToSale(order, vm),
                      icon: _isConverting
                          ? const SizedBox(
                              height: AppSizes.iconSm,
                              width: AppSizes.iconSm,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.point_of_sale_outlined,
                              size: AppSizes.iconSm,
                            ),
                      label: const Text('Convert to Sale'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: AppSizes.xs,
                        ),
                        minimumSize: const Size(80, 32),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
