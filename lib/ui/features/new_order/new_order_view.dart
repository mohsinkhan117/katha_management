// lib/ui/features/new_order/new_order_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/new_order/new_order_item_model.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/ui/features/new_order/new_order_view_model.dart';
import 'package:provider/provider.dart';

class NewOrderView extends StatelessWidget {
  static const routeName = '/new-order-view';
  static Route route({String? partyId}) {
    return MaterialPageRoute(
      builder: (context) => NewOrderView(partyId: partyId),
      settings: RouteSettings(name: routeName, arguments: partyId),
    );
  }

  const NewOrderView({super.key, this.partyId});
  final String? partyId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewOrderViewModel(initialPartyId: partyId),
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
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _partyNameController.dispose();
    _partyPhoneController.dispose();
    _noteController.dispose();
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
      appBar: AppBar(title: const Text('New Order')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          const _StatusBadge(),
          const SizedBox(height: AppSizes.spaceBtwSections),
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
                  context.read<NewOrderViewModel>().setPartyManual(
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
                  context.read<NewOrderViewModel>().setPartyManual(
                    name: _partyNameController.text,
                    phone: value,
                  ),
            ),
          ],

          const SizedBox(height: AppSizes.spaceBtwSections),
          const _SectionLabel('Expected Delivery'),
          const SizedBox(height: AppSizes.sm),
          InkWell(
            onTap: () => _pickDeliveryDate(context),
            borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Delivery date (optional)',
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  size: AppSizes.iconSm,
                ),
              ),
              child: Text(
                vm.expectedDeliveryDate != null
                    ? _formatDate(vm.expectedDeliveryDate!)
                    : 'Select expected delivery date',
                style: TextStyle(
                  color: vm.expectedDeliveryDate != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spaceBtwSections),
          const _SectionLabel('Items'),
          const SizedBox(height: AppSizes.sm),
          _ItemsList(items: vm.items),
          const SizedBox(height: AppSizes.sm),
          const _AddItemForm(),
          const SizedBox(height: AppSizes.spaceBtwSections),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            onChanged: (value) =>
                context.read<NewOrderViewModel>().setNote(value),
          ),
          const SizedBox(height: AppSizes.spaceBtwSections),
          _TotalCard(totalAmount: vm.totalAmount, itemCount: vm.items.length),
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
                      final orderVm = context.read<NewOrderViewModel>();
                      final success = await orderVm.saveOrder();
                      if (!context.mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order placed successfully'),
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
                      'Place Order',
                      style: TextStyle(color: AppColors.textWhite),
                    ),
            ),
          ),
        ],
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
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.radio_button_checked,
            color: AppColors.secondary,
            size: AppSizes.iconXs,
          ),
          SizedBox(width: AppSizes.xs),
          Text(
            'New orders start as Placed',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSm,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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

class _ItemsList extends StatelessWidget {
  const _ItemsList({required this.items});
  final List<OrderItemModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
        child: Text(
          'No items added yet',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Card(
          elevation: AppSizes.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
          ),
          margin: const EdgeInsets.only(bottom: AppSizes.sm),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: AppSizes.xs,
            ),
            title: Text(
              item.productName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              '${item.quantity} x Rs ${item.unitPrice.toStringAsFixed(0)}'
              '${item.discount > 0 ? ' - Rs ${item.discount.toStringAsFixed(0)} disc.' : ''}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rs ${item.subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.error,
                    size: AppSizes.iconSm,
                  ),
                  onPressed: () =>
                      context.read<NewOrderViewModel>().removeItem(index),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _AddItemForm extends StatefulWidget {
  const _AddItemForm();

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final _productController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');

  @override
  void dispose() {
    _productController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final name = _productController.text.trim();
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;

    if (name.isEmpty || qty <= 0 || price <= 0) return;

    context.read<NewOrderViewModel>().addItem(
      productName: name,
      quantity: qty,
      unitPrice: price,
      discount: discount,
    );

    _productController.clear();
    _qtyController.text = '1';
    _priceController.clear();
    _discountController.text = '0';
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Column(
          children: [
            TextField(
              controller: _productController,
              decoration: const InputDecoration(labelText: 'Product name'),
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
                    decoration: const InputDecoration(labelText: 'Unit price'),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Discount'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleAdd,
                icon: const Icon(Icons.add, color: AppColors.secondary),
                label: const Text(
                  'Add Item',
                  style: TextStyle(color: AppColors.secondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalAmount, required this.itemCount});
  final double totalAmount;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$itemCount item${itemCount == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeMd,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Rs ${totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeLg,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
