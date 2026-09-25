// lib/ui/features/new_order/new_order_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:katha_management/core/constants/app_strings/app_strings.dart';
import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/models/product/product_model.dart';
import 'package:katha_management/core/models/product/product_size_model.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'new_order_view_model.dart';

class NewOrderView extends StatelessWidget {
  static const routeName = '/new-order-view';
  static Route route({String? partyId, OrderModel? orderToEdit}) {
    return MaterialPageRoute(
      builder: (context) =>
          NewOrderView(partyId: partyId, orderToEdit: orderToEdit),
      settings: RouteSettings(
        name: routeName,
        arguments: orderToEdit ?? partyId,
      ),
    );
  }

  const NewOrderView({super.key, this.partyId, this.orderToEdit});
  final String? partyId;
  final OrderModel? orderToEdit;

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final effectiveOrder =
        orderToEdit ?? (routeArgs is OrderModel ? routeArgs : null);
    final effectivePartyId =
        partyId ?? (routeArgs is String ? routeArgs : null);

    return ChangeNotifierProvider(
      create: (_) => NewOrderViewModel(
        initialPartyId: effectivePartyId,
        orderToEdit: effectiveOrder,
      ),
      child: const _NewOrderViewBody(),
    );
  }
}

class _NewOrderViewBody extends StatefulWidget {
  const _NewOrderViewBody();

  @override
  State<_NewOrderViewBody> createState() => _NewOrderViewBodyState();
}

class _NewOrderViewBodyState extends State<_NewOrderViewBody> {
  final _partyNameController = TextEditingController();
  final _partyPhoneController = TextEditingController();
  final _advancePaidController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final vm = context.read<NewOrderViewModel>();
    if (vm.isEditing) {
      _partyNameController.text = vm.partyName;
      _partyPhoneController.text = vm.partyPhone;
      if (vm.advancePaid > 0) {
        _advancePaidController.text = vm.advancePaid.toStringAsFixed(0);
      }
      _noteController.text = vm.note ?? '';
    }
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _partyPhoneController.dispose();
    _advancePaidController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDeliveryDate(BuildContext context) async {
    final vm = context.read<NewOrderViewModel>();
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: vm.expectedDeliveryDate ?? now.add(const Duration(days: 1)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      vm.setExpectedDeliveryDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NewOrderViewModel>();

    if (vm.linkedParty != null) {
      if (_partyNameController.text != vm.partyName) {
        _partyNameController.text = vm.partyName;
      }
      if (_partyPhoneController.text != vm.partyPhone) {
        _partyPhoneController.text = vm.partyPhone;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          vm.isEditing ? AppStrings.editOrderTitle : AppStrings.newOrderButton,
        ),
        actions: [
          if (vm.isEditing && vm.canEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: AppStrings.deleteOrderButton,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text(AppStrings.deleteOrderTitle),
                    content: const Text(AppStrings.deleteOrderMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(AppStrings.no),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text(AppStrings.deleteOrderButton),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final orderVm = context.read<NewOrderViewModel>();
                  final deleted = await orderVm.deleteOrder();
                  if (deleted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.orderDeletedSuccess),
                      ),
                    );
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop(true);
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          if (vm.isEditing && !vm.canEdit) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppSizes.sm),
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.cannotEditDeliveredOrPaidOrder,
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const _StatusBadge(),
          const SizedBox(height: AppSizes.spaceBtwSections),

          // ─── Party Selection ──────────────────────────────────────
          const _SectionLabel(AppStrings.partyDetailsSection),
          const SizedBox(height: AppSizes.sm),

          if (vm.linkedParty != null) ...[
            _LinkedPartyCard(
              party: vm.linkedParty!,
              onClear: () {
                vm.clearSelectedParty();
                _partyNameController.clear();
                _partyPhoneController.clear();
              },
            ),
          ] else ...[
            if (vm.availableParties.isNotEmpty) ...[
              _PartyPickerDropdown(
                parties: vm.availableParties,
                onSelected: (party) {
                  vm.selectParty(party);
                  _partyNameController.text = party.name;
                  _partyPhoneController.text = party.phone ?? '';
                },
              ),
              const SizedBox(height: AppSizes.sm),
            ],
            TextField(
              controller: _partyNameController,
              decoration: const InputDecoration(
                labelText: AppStrings.partyNameLabel,
              ),
              onChanged: (value) =>
                  context.read<NewOrderViewModel>().setPartyManual(
                    name: value,
                    phone: _partyPhoneController.text,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _partyPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: AppStrings.partyPhoneLabel,
              ),
              onChanged: (value) =>
                  context.read<NewOrderViewModel>().setPartyManual(
                    name: _partyNameController.text,
                    phone: value,
                  ),
            ),
          ],

          const SizedBox(height: AppSizes.spaceBtwSections),

          // ─── Expected Delivery Date ────────────────────────────────
          const _SectionLabel(AppStrings.expectedDeliveryDateLabel),
          const SizedBox(height: AppSizes.sm),
          InkWell(
            onTap: () => _pickDeliveryDate(context),
            borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: AppStrings.deliveryDateOptional,
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  size: AppSizes.iconSm,
                ),
              ),
              child: Text(
                vm.expectedDeliveryDate != null
                    ? _formatDate(vm.expectedDeliveryDate!)
                    : AppStrings.selectExpectedDeliveryDateHint,
                style: TextStyle(
                  color: vm.expectedDeliveryDate != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSizes.spaceBtwSections),

          // ─── Product Catalog & Selection ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel(AppStrings.selectProductsSection),
              Text(
                '${vm.items.length} ${AppStrings.itemsPlural} added',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          const Text(
            AppStrings.selectProductsInstruction,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppStrings.searchCatalogHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        vm.setProductSearchQuery('');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => vm.setProductSearchQuery(val),
          ),
          const SizedBox(height: AppSizes.sm),

          if (vm.isLoadingProducts) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.lg),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (vm.filteredProducts.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.lightContainer,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              ),
              child: const Center(
                child: Text(
                  AppStrings.noProductsFoundInCatalog,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ] else ...[
            ...vm.filteredProducts.map((product) {
              return _OrderProductCardWithDropdown(product: product);
            }),
          ],

          const SizedBox(height: AppSizes.spaceBtwSections),

          // ─── Custom / Non-Catalog Item ──────────────────────────────
          const _OrderCustomItemExpander(),

          const SizedBox(height: AppSizes.spaceBtwSections),

          // ─── Advance Payment Section ────────────────────────────────
          const _SectionLabel(AppStrings.advancePaymentSection),
          const SizedBox(height: AppSizes.xs),

          // Quick Presets for Order Advance
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.success,
                  ),
                  label: Text(
                    '${AppStrings.quickFullPaid} (Rs ${vm.totalAmount.toStringAsFixed(0)})',
                  ),
                  onPressed: vm.totalAmount <= 0
                      ? null
                      : () {
                          _advancePaidController.text = vm.totalAmount
                              .toStringAsFixed(0);
                          context.read<NewOrderViewModel>().setAdvancePaid(
                            vm.totalAmount,
                          );
                        },
                ),
                const SizedBox(width: AppSizes.xs),
                ActionChip(
                  avatar: const Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(AppStrings.quickToken500),
                  onPressed: () {
                    _advancePaidController.text = '500';
                    context.read<NewOrderViewModel>().setAdvancePaid(500);
                  },
                ),
                const SizedBox(width: AppSizes.xs),
                ActionChip(
                  avatar: const Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(AppStrings.quickToken1000),
                  onPressed: () {
                    _advancePaidController.text = '1000';
                    context.read<NewOrderViewModel>().setAdvancePaid(1000);
                  },
                ),
                const SizedBox(width: AppSizes.xs),
                ActionChip(
                  avatar: const Icon(
                    Icons.cancel_outlined,
                    size: 16,
                    color: AppColors.tetraColor,
                  ),
                  label: const Text(AppStrings.quickUnpaid),
                  onPressed: () {
                    _advancePaidController.text = '0';
                    context.read<NewOrderViewModel>().setAdvancePaid(0);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          TextField(
            controller: _advancePaidController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: AppStrings.advancePaidLabel,
              prefixText: AppStrings.currencyPrefix,
              helperText: AppStrings.advancePaidHelper,
            ),
            onChanged: (value) => context
                .read<NewOrderViewModel>()
                .setAdvancePaid(double.tryParse(value) ?? 0),
          ),
          const SizedBox(height: AppSizes.sm),

          // Payment Mode Selector (when advancePaid > 0)
          if (vm.advancePaid > 0) ...[
            const Text(
              AppStrings.paymentModeLabel,
              style: TextStyle(
                fontSize: AppSizes.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PaymentMode.values.map((mode) {
                  final isSelected = vm.paymentMode == mode;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSizes.xs),
                    child: ChoiceChip(
                      label: Text(mode.label),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.textWhite
                            : AppColors.textPrimary,
                      ),
                      onSelected: (_) => context
                          .read<NewOrderViewModel>()
                          .setPaymentMode(mode),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
          ],

          // ─── Note ──────────────────────────────────────────────────
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: AppStrings.noteOptional,
            ),
            onChanged: (value) =>
                context.read<NewOrderViewModel>().setNote(value),
          ),

          const SizedBox(height: AppSizes.spaceBtwSections),

          // ─── Totals Card & Place Order ─────────────────────────────
          _OrderTotalCard(
            totalAmount: vm.totalAmount,
            advancePaid: vm.advancePaid,
            balanceDue: vm.balanceDue,
            itemCount: vm.items.length,
          ),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              vm.errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSizes.spaceBtwSections),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed:
                  vm.isSaving || !vm.canSave || (vm.isEditing && !vm.canEdit)
                  ? null
                  : () async {
                      final orderVm = context.read<NewOrderViewModel>();
                      final success = await orderVm.saveOrder();
                      if (!context.mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              orderVm.isEditing
                                  ? AppStrings.orderUpdatedSuccess
                                  : AppStrings.orderPlacedSuccess,
                            ),
                          ),
                        );
                        if (Navigator.canPop(context)) {
                          Navigator.of(context).pop(true);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                ),
              ),
              child: vm.isSaving
                  ? const SizedBox(
                      height: AppSizes.iconMd,
                      width: AppSizes.iconMd,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textWhite,
                      ),
                    )
                  : Text(
                      vm.isEditing
                          ? AppStrings.updateOrderButton
                          : AppStrings.placeOrderButton,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSizes.spaceBtwSections),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: AppSizes.iconSm,
            color: AppColors.secondary,
          ),
          SizedBox(width: AppSizes.xs),
          Text(
            AppStrings.newOrderPlacedStatusInfo,
            style: TextStyle(
              fontSize: AppSizes.fontSizeSm,
              color: AppColors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderProductCardWithDropdown extends StatefulWidget {
  const _OrderProductCardWithDropdown({required this.product});
  final ProductModel product;

  @override
  State<_OrderProductCardWithDropdown> createState() =>
      _OrderProductCardWithDropdownState();
}

class _OrderProductCardWithDropdownState
    extends State<_OrderProductCardWithDropdown> {
  late final TextEditingController _priceController;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    final defaultPrice = widget.product.hasSizes
        ? widget.product.sizes.first.finalPrice
        : widget.product.finalPrice;
    _priceController = TextEditingController(
      text: defaultPrice.toStringAsFixed(0),
    );
    _qtyController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NewOrderViewModel>();
    final isSelected = vm.isProductSelected(widget.product.id);
    final state = vm.getProductState(widget.product.id);
    final hasSizes = widget.product.hasSizes;

    if (state != null) {
      if (_priceController.text != state.unitPrice.toStringAsFixed(0) &&
          !_priceController.selection.isValid) {
        _priceController.text = state.unitPrice.toStringAsFixed(0);
      }
      if (_qtyController.text != state.quantity.toStringAsFixed(0) &&
          !_qtyController.selection.isValid) {
        _qtyController.text = state.quantity.toStringAsFixed(0);
      }
    }

    return Card(
      elevation: AppSizes.cardElevation,
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
        side: isSelected
            ? BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.5),
                width: 1.2,
              )
            : BorderSide.none,
      ),
      color: isSelected
          ? AppColors.secondary.withValues(alpha: 0.03)
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Title & Toggle Checkbox
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: AppColors.secondary,
                  onChanged: (checked) {
                    vm.toggleProduct(widget.product, checked ?? false);
                    if (checked == true) {
                      final defaultPrice = widget.product.hasSizes
                          ? widget.product.sizes.first.finalPrice
                          : widget.product.finalPrice;
                      _priceController.text = defaultPrice.toStringAsFixed(0);
                      _qtyController.text = '1';
                    }
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: AppSizes.fontSizeMd,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (widget.product.category != null &&
                          widget.product.category!.isNotEmpty)
                        Text(
                          widget.product.category!,
                          style: const TextStyle(
                            fontSize: AppSizes.fontSizeSm,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isSelected)
                  Text(
                    hasSizes
                        ? 'from ${AppStrings.currencyPrefix}${widget.product.sizes.first.finalPrice.toStringAsFixed(0)}'
                        : '${AppStrings.currencyPrefix}${widget.product.finalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (isSelected && state != null)
                  Text(
                    '${AppStrings.currencyPrefix}${state.subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeMd,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
              ],
            ),

            // Expanded Controls when product is selected
            if (isSelected && state != null) ...[
              const Divider(height: 12),

              // ─── Size Variant Dropdown (if sizes available) ────────
              if (hasSizes) ...[
                const SizedBox(height: 4),
                DropdownButtonFormField<ProductSizeModel>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.selectPackageSizeLabel,
                    prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  initialValue: widget.product.sizes.firstWhere(
                    (s) => s.id == state.sizeId,
                    orElse: () => widget.product.sizes.first,
                  ),
                  items: widget.product.sizes.map((size) {
                    return DropdownMenuItem<ProductSizeModel>(
                      value: size,
                      child: Text(
                        '${size.label}  —  ${AppStrings.currencyPrefix}${size.finalPrice.toStringAsFixed(0)}${size.hasDiscount ? ' (${size.discountPercentage.toStringAsFixed(0)}${AppStrings.percentSuffix} off)' : ''}',
                        style: const TextStyle(fontSize: AppSizes.fontSizeSm),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (newSize) {
                    if (newSize != null) {
                      vm.changeProductSize(widget.product, newSize);
                      _priceController.text = newSize.finalPrice
                          .toStringAsFixed(0);
                    }
                  },
                ),
                const SizedBox(height: AppSizes.sm),
              ],

              // ─── Quantity and Mutable Price Row ─────────────────────
              Row(
                children: [
                  // Quantity Stepper
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          final current = state.quantity;
                          if (current > 1) {
                            vm.updateProductQuantity(
                              widget.product.id,
                              current - 1,
                            );
                            _qtyController.text = (current - 1).toStringAsFixed(
                              0,
                            );
                          } else {
                            vm.toggleProduct(widget.product, false);
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 48,
                        height: 38,
                        child: TextField(
                          controller: _qtyController,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: (val) {
                            final q = double.tryParse(val) ?? 1.0;
                            vm.updateProductQuantity(widget.product.id, q);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          final current = state.quantity;
                          vm.updateProductQuantity(
                            widget.product.id,
                            current + 1,
                          );
                          _qtyController.text = (current + 1).toStringAsFixed(
                            0,
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(width: AppSizes.md),

                  // Mutable Price Field
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: AppStrings.priceLabel,
                          prefixText: AppStrings.currencyPrefix,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                          helperText: state.unitPrice != state.defaultPrice
                              ? 'Default: ${AppStrings.currencyPrefix}${state.defaultPrice.toStringAsFixed(0)}'
                              : null,
                        ),
                        onChanged: (val) {
                          final p = double.tryParse(val) ?? 0.0;
                          vm.updateProductPrice(widget.product.id, p);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderCustomItemExpander extends StatefulWidget {
  const _OrderCustomItemExpander();

  @override
  State<_OrderCustomItemExpander> createState() =>
      _OrderCustomItemExpanderState();
}

class _OrderCustomItemExpanderState extends State<_OrderCustomItemExpander> {
  bool _isExpanded = false;
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final name = _nameController.text.trim();
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;

    if (name.isEmpty || qty <= 0 || price <= 0) return;

    context.read<NewOrderViewModel>().addCustomItem(
      productName: name,
      quantity: qty,
      unitPrice: price,
      discount: discount,
    );

    _nameController.clear();
    _qtyController.text = '1';
    _priceController.clear();
    _discountController.text = '0';
    setState(() => _isExpanded = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NewOrderViewModel>();

    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_shopping_cart, color: AppColors.secondary),
                      SizedBox(width: AppSizes.sm),
                      Text(
                        AppStrings.customItemSection,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (_isExpanded) ...[
              const SizedBox(height: AppSizes.sm),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.itemNameLabel,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: AppStrings.quantityLabel,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: AppStrings.rateOrPriceLabel,
                        prefixText: AppStrings.currencyPrefix,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: TextField(
                      controller: _discountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: AppStrings.discountLabel,
                        prefixText: AppStrings.currencyPrefix,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _handleAdd,
                  child: const Text(AppStrings.addCustomItemButton),
                ),
              ),
            ],
            if (vm.customItems.isNotEmpty) ...[
              const Divider(height: 16),
              ...List.generate(vm.customItems.length, (index) {
                final item = vm.customItems[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.productName),
                  subtitle: Text(
                    '${item.quantity} x ${AppStrings.currencyPrefix}${item.unitPrice.toStringAsFixed(0)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AppStrings.currencyPrefix}${item.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.error,
                        ),
                        onPressed: () => vm.removeCustomItem(index),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkedPartyCard extends StatelessWidget {
  const _LinkedPartyCard({required this.party, required this.onClear});
  final PartyModel party;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
      ),
      color: AppColors.secondary.withValues(alpha: 0.08),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary,
          child: Text(
            party.name.isNotEmpty ? party.name[0] : '?',
            style: const TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          party.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          party.phone ?? AppStrings.noPhoneOnFile,
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: AppSizes.iconSm),
          onPressed: onClear,
          tooltip: AppStrings.changePartyTooltip,
        ),
      ),
    );
  }
}

class _PartyPickerDropdown extends StatelessWidget {
  const _PartyPickerDropdown({required this.parties, required this.onSelected});

  final List<PartyModel> parties;
  final ValueChanged<PartyModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PartyModel>(
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: AppStrings.selectExistingCustomer,
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: parties.map((party) {
        final phoneText =
            (party.phone != null && party.phone!.trim().isNotEmpty)
            ? ' (${party.phone!.trim()})'
            : '';
        return DropdownMenuItem<PartyModel>(
          value: party,
          child: Text(
            '${party.name}$phoneText',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (party) {
        if (party != null) onSelected(party);
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: AppSizes.fontSizeLg,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _OrderTotalCard extends StatelessWidget {
  const _OrderTotalCard({
    required this.totalAmount,
    required this.advancePaid,
    required this.balanceDue,
    required this.itemCount,
  });

  final double totalAmount;
  final double advancePaid;
  final double balanceDue;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
      ),
      color: AppColors.secondary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.estimatedTotalLabel,
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeMd,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$itemCount ${itemCount == 1 ? AppStrings.itemSingular : AppStrings.itemsPlural}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${AppStrings.currencyPrefix}${totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeLg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            if (advancePaid > 0) ...[
              const Divider(height: AppSizes.spaceBtwItems),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppStrings.advancePaidLabel,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${AppStrings.currencyPrefix}${advancePaid.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeMd,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppStrings.balanceDueLabel,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: AppColors.tetraColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${AppStrings.currencyPrefix}${balanceDue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeMd,
                      fontWeight: FontWeight.bold,
                      color: balanceDue > 0
                          ? AppColors.tetraColor
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
