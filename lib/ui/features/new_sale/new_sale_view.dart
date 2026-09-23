// lib/ui/features/new_sale/new_sale_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/product/product_model.dart';
import 'package:katha_management/core/models/product/product_size_model.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'new_sale_view_model.dart';

class NewSaleView extends StatelessWidget {
  static const routeName = '/new-sale-view';
  static Route route({String? partyId}) {
    return MaterialPageRoute(
      builder: (context) => NewSaleView(partyId: partyId),
      settings: RouteSettings(name: routeName, arguments: partyId),
    );
  }

  const NewSaleView({super.key, this.partyId});
  final String? partyId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewSaleViewModel(initialPartyId: partyId),
      child: const _NewSaleViewBody(),
    );
  }
}

class _NewSaleViewBody extends StatefulWidget {
  const _NewSaleViewBody();

  @override
  State<_NewSaleViewBody> createState() => _NewSaleViewBodyState();
}

class _NewSaleViewBodyState extends State<_NewSaleViewBody> {
  final _partyNameController = TextEditingController();
  final _partyPhoneController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _partyNameController.dispose();
    _partyPhoneController.dispose();
    _paidAmountController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NewSaleViewModel>();

    if (vm.linkedParty != null) {
      if (_partyNameController.text != vm.partyName) {
        _partyNameController.text = vm.partyName;
      }
      if (_partyPhoneController.text != vm.partyPhone) {
        _partyPhoneController.text = vm.partyPhone;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          // ─── Party Selection ──────────────────────────────────────
          const _SectionLabel('Party Details'),
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
              decoration: const InputDecoration(labelText: 'Party name *'),
              onChanged: (value) =>
                  context.read<NewSaleViewModel>().setPartyManual(
                    name: value,
                    phone: _partyPhoneController.text,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _partyPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
              onChanged: (value) =>
                  context.read<NewSaleViewModel>().setPartyManual(
                    name: _partyNameController.text,
                    phone: value,
                  ),
            ),
          ],

          const SizedBox(height: AppSizes.spaceBtwSections),

          // ─── Product Catalog & Selection ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('Select Products'),
              Text(
                '${vm.items.length} items added',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          const Text(
            'Check products to add. Select size variants from dropdown and customize prices if needed.',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products by name, sku, or category...',
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
                  'No products found in catalog. You can add one below.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ] else ...[
            ...vm.filteredProducts.map((product) {
              return _ProductCardWithDropdown(product: product);
            }),
          ],

          const SizedBox(height: AppSizes.spaceBtwSections),

          // ─── Custom / Non-Catalog Item ──────────────────────────────
          const _CustomItemExpander(),

          const SizedBox(height: AppSizes.spaceBtwSections),

          // ─── Payment & Settlement ──────────────────────────────────
          const _SectionLabel('Payment & Settlement'),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _paidAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Paid amount upfront (optional)',
              prefixText: 'Rs ',
              helperText: 'Will automatically be credited & recorded to ledger',
            ),
            onChanged: (value) => context
                .read<NewSaleViewModel>()
                .setPaidAmount(double.tryParse(value) ?? 0),
          ),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            onChanged: (value) =>
                context.read<NewSaleViewModel>().setNote(value),
          ),

          const SizedBox(height: AppSizes.spaceBtwSections),

          // ─── Totals Card & Save ────────────────────────────────────
          _TotalsCard(vm: vm),
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
              onPressed: vm.isSaving || !vm.canSave
                  ? null
                  : () async {
                      final saleVm = context.read<NewSaleViewModel>();
                      final success = await saleVm.saveSale();
                      if (!context.mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sale saved successfully'),
                          ),
                        );
                        if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
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
                  : const Text(
                      'Save Sale',
                      style: TextStyle(
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

class _ProductCardWithDropdown extends StatefulWidget {
  const _ProductCardWithDropdown({required this.product});
  final ProductModel product;

  @override
  State<_ProductCardWithDropdown> createState() =>
      _ProductCardWithDropdownState();
}

class _ProductCardWithDropdownState extends State<_ProductCardWithDropdown> {
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
    final vm = context.watch<NewSaleViewModel>();
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
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 1.2,
              )
            : BorderSide.none,
      ),
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.03)
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
                  activeColor: AppColors.primary,
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
                        ? 'from Rs ${widget.product.sizes.first.finalPrice.toStringAsFixed(0)}'
                        : 'Rs ${widget.product.finalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (isSelected && state != null)
                  Text(
                    'Rs ${state.subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeMd,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
                  decoration: const InputDecoration(
                    labelText: 'Select Package Size',
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
                        '${size.label}  —  Rs ${size.finalPrice.toStringAsFixed(0)}${size.hasDiscount ? ' (${size.discountPercentage.toStringAsFixed(0)}% off)' : ''}',
                        style: const TextStyle(fontSize: AppSizes.fontSizeSm),
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
                          labelText: 'Price',
                          prefixText: 'Rs ',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                          helperText: state.unitPrice != state.defaultPrice
                              ? 'Default: Rs ${state.defaultPrice.toStringAsFixed(0)}'
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

class _CustomItemExpander extends StatefulWidget {
  const _CustomItemExpander();

  @override
  State<_CustomItemExpander> createState() => _CustomItemExpanderState();
}

class _CustomItemExpanderState extends State<_CustomItemExpander> {
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

    context.read<NewSaleViewModel>().addCustomItem(
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
    final vm = context.watch<NewSaleViewModel>();

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
                        'Add Custom / Non-Catalog Item',
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
                decoration: const InputDecoration(labelText: 'Item name'),
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
                      decoration: const InputDecoration(labelText: 'Qty'),
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
                        labelText: 'Unit price',
                        prefixText: 'Rs ',
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
                        labelText: 'Discount',
                        prefixText: 'Rs ',
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
                  child: const Text('Add Custom Item'),
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
                    '${item.quantity} x Rs ${item.unitPrice.toStringAsFixed(0)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rs ${item.subtotal.toStringAsFixed(0)}',
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
      color: AppColors.primary.withValues(alpha: 0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
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
          party.phone ?? 'No phone on file',
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: AppSizes.iconSm),
          onPressed: onClear,
          tooltip: 'Change Party',
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
      decoration: const InputDecoration(
        labelText: 'Select Existing Customer',
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: parties.map((party) {
        return DropdownMenuItem<PartyModel>(
          value: party,
          child: Text(
            '${party.name}${party.phone != null ? ' (${party.phone})' : ''}',
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

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.vm});
  final NewSaleViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
      ),
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Sale Amount',
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeMd,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Rs ${vm.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeLg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (vm.paidAmount > 0) ...[
              const SizedBox(height: AppSizes.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Paid Upfront',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Rs ${vm.paidAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Balance Due',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Rs ${vm.balanceDue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSm,
                      color: vm.balanceDue > 0
                          ? AppColors.tetraColor
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
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
