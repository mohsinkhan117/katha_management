// lib/ui/features/add_product/add_product_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/product/product_model.dart';
import 'package:katha_management/core/models/product/product_size_model.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'add_product_view_model.dart';

class AddProductView extends StatelessWidget {
  static const String routeName = '/add-product-view';
  static Route route({ProductModel? existingProduct}) {
    return MaterialPageRoute(
      builder: (context) => AddProductView(existingProduct: existingProduct),
      settings: const RouteSettings(name: routeName),
    );
  }

  const AddProductView({super.key, this.existingProduct});
  final ProductModel? existingProduct;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddProductViewModel(existingProduct: existingProduct),
      child: const _AddProductViewBody(),
    );
  }
}

class _AddProductViewBody extends StatefulWidget {
  const _AddProductViewBody();

  @override
  State<_AddProductViewBody> createState() => _AddProductViewBodyState();
}

class _AddProductViewBodyState extends State<_AddProductViewBody> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockQuantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final vm = context.read<AddProductViewModel>();
    _nameController.text = vm.name;
    _descriptionController.text = vm.description;
    _skuController.text = vm.sku;
    _categoryController.text = vm.category;
    _unitController.text = vm.unit;
    _retailPriceController.text = vm.retailPrice > 0
        ? vm.retailPrice.toStringAsFixed(0)
        : '';
    _discountPercentageController.text = vm.discountPercentage > 0
        ? vm.discountPercentage.toStringAsFixed(0)
        : '';
    _costPriceController.text = vm.costPrice > 0
        ? vm.costPrice.toStringAsFixed(0)
        : '';
    _stockQuantityController.text = vm.stockQuantity > 0
        ? vm.stockQuantity.toString()
        : '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _retailPriceController.dispose();
    _discountPercentageController.dispose();
    _costPriceController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddProductViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          const _SectionLabel('Basic Info'),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Product name *'),
            onChanged: (value) =>
                context.read<AddProductViewModel>().setName(value),
          ),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
            onChanged: (value) =>
                context.read<AddProductViewModel>().setDescription(value),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skuController,
                  decoration: const InputDecoration(labelText: 'SKU / Code'),
                  onChanged: (value) =>
                      context.read<AddProductViewModel>().setSku(value),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                  onChanged: (value) =>
                      context.read<AddProductViewModel>().setCategory(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _unitController,
            decoration: const InputDecoration(
              labelText: 'Base unit (optional)',
              helperText:
                  'e.g. piece, kg, box — what sizes below are variants of',
            ),
            onChanged: (value) =>
                context.read<AddProductViewModel>().setUnit(value),
          ),

          const SizedBox(height: AppSizes.spaceBtwSections),

          // ─── Selling Price ──────────────────────────────────────
          const _SectionLabel('Selling Price'),
          const SizedBox(height: AppSizes.xs),
          const Text(
            'What the customer sees and pays.',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _retailPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Retail price *',
                    prefixText: 'Rs ',
                  ),
                  onChanged: (value) => context
                      .read<AddProductViewModel>()
                      .setRetailPrice(double.tryParse(value) ?? 0),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: TextField(
                  controller: _discountPercentageController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Discount',
                    suffixText: '%',
                  ),
                  onChanged: (value) => context
                      .read<AddProductViewModel>()
                      .setDiscountPercentage(double.tryParse(value) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          _FinalPriceCard(
            retailPrice: vm.retailPrice,
            discountAmount: vm.discountAmountPreview,
            finalPrice: vm.finalPricePreview,
            hasDiscount: vm.hasDiscountPreview,
          ),

          const SizedBox(height: AppSizes.spaceBtwSections),

          // ─── Cost & Profit Margin ───────────────────────────────
          const _SectionLabel('Cost & Profit Margin'),
          const SizedBox(height: AppSizes.xs),
          const Text(
            'What this product costs you to buy or produce. Used only '
            'to show your profit below — customers never see this.',
            style: TextStyle(
              fontSize: AppSizes.fontSizeSm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _costPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cost price',
                    prefixText: 'Rs ',
                  ),
                  onChanged: (value) => context
                      .read<AddProductViewModel>()
                      .setCostPrice(double.tryParse(value) ?? 0),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: TextField(
                  controller: _stockQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock qty (optional)',
                  ),
                  onChanged: (value) => context
                      .read<AddProductViewModel>()
                      .setStockQuantity(int.tryParse(value) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          _ProfitMarginCard(
            profitMargin: vm.profitMarginPreview,
            profitMarginPercentage: vm.profitMarginPercentagePreview,
          ),

          const SizedBox(height: AppSizes.spaceBtwSections),
          const _SectionLabel('Status'),
          const SizedBox(height: AppSizes.sm),
          _StatusSelector(selected: vm.status),
          const SizedBox(height: AppSizes.spaceBtwSections),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('Size / Price Variants'),
              const Text(
                'Optional',
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSm,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          _SizesList(sizes: vm.sizes),
          const SizedBox(height: AppSizes.sm),
          const _AddSizeForm(),
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
                      final productVm = context.read<AddProductViewModel>();
                      final wasEditing = productVm.isEditing;
                      final success = await productVm.saveProduct();
                      if (!context.mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              wasEditing ? 'Product updated' : 'Product added',
                            ),
                          ),
                        );
                        Navigator.of(context).pop();
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
                      vm.isEditing ? 'Update Product' : 'Save Product',
                      style: const TextStyle(color: AppColors.textWhite),
                    ),
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

/// Live readout of what the customer will actually be charged, shown
/// right under the retail price / discount fields so the calculation
/// is visible as the user types rather than only appearing after save.
class _FinalPriceCard extends StatelessWidget {
  const _FinalPriceCard({
    required this.retailPrice,
    required this.discountAmount,
    required this.finalPrice,
    required this.hasDiscount,
  });

  final double retailPrice;
  final double discountAmount;
  final double finalPrice;
  final bool hasDiscount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Customer Pays',
            style: TextStyle(
              fontSize: AppSizes.fontSizeMd,
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            children: [
              if (hasDiscount) ...[
                Text(
                  'Rs ${retailPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSm,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
              ],
              Text(
                'Rs ${finalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: AppSizes.fontSizeLg,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Live readout of profit per unit — replaces the old vague "used for
/// margin later" helper text with an actual number, since a computed
/// figure needs no further explanation.
class _ProfitMarginCard extends StatelessWidget {
  const _ProfitMarginCard({
    required this.profitMargin,
    required this.profitMarginPercentage,
  });

  final double? profitMargin;
  final double? profitMarginPercentage;

  @override
  Widget build(BuildContext context) {
    if (profitMargin == null) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.lightContainer,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
        child: const Text(
          'Enter a cost price to see your profit margin here.',
          style: TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final isLoss = profitMargin! < 0;
    final color = isLoss ? AppColors.error : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isLoss ? 'Selling Below Cost' : 'Profit Margin',
            style: TextStyle(fontSize: AppSizes.fontSizeMd, color: color),
          ),
          Text(
            '${isLoss ? '-' : ''}Rs ${profitMargin!.abs().toStringAsFixed(0)} '
            'per unit'
            '${profitMarginPercentage != null ? ' (${profitMarginPercentage!.abs().toStringAsFixed(0)}%)' : ''}',
            style: TextStyle(
              fontSize: AppSizes.fontSizeMd,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.selected});
  final ProductStatus selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.sm,
      children: ProductStatus.values.map((status) {
        final isSelected = status == selected;
        final chipColor = status == ProductStatus.inStock
            ? AppColors.success
            : AppColors.error;
        return ChoiceChip(
          label: Text(status.label),
          selected: isSelected,
          selectedColor: chipColor,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
          ),
          onSelected: (_) =>
              context.read<AddProductViewModel>().setStatus(status),
        );
      }).toList(),
    );
  }
}

class _SizesList extends StatelessWidget {
  const _SizesList({required this.sizes});
  final List<ProductSizeModel> sizes;

  @override
  Widget build(BuildContext context) {
    if (sizes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
        child: Text(
          'No size variants — product will use the retail price above',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: List.generate(sizes.length, (index) {
        final size = sizes[index];
        final margin = size.profitMargin;
        final marginPct = size.profitMarginPercentage;

        return Card(
          elevation: AppSizes.cardElevation,
          margin: const EdgeInsets.only(bottom: AppSizes.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: AppSizes.xs,
            ),
            title: Text(
              size.label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  size.hasDiscount
                      ? 'Rs ${size.price.toStringAsFixed(0)} \u2192 Rs ${size.finalPrice.toStringAsFixed(0)} '
                            '(${size.discountPercentage.toStringAsFixed(0)}% off)'
                      : 'Rs ${size.finalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeSm,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (size.costPrice != null && size.costPrice! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Cost: Rs ${size.costPrice!.toStringAsFixed(0)}'
                      ' • ${margin != null && margin < 0 ? "Loss" : "Margin"}: '
                      'Rs ${margin != null ? margin.abs().toStringAsFixed(0) : "0"}'
                      '${marginPct != null ? " (${marginPct.abs().toStringAsFixed(0)}%)" : ""}',
                      style: TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        fontWeight: FontWeight.w500,
                        color: margin != null && margin < 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.close,
                color: AppColors.error,
                size: AppSizes.iconSm,
              ),
              onPressed: () =>
                  context.read<AddProductViewModel>().removeSize(index),
            ),
          ),
        );
      }),
    );
  }
}

class _AddSizeForm extends StatefulWidget {
  const _AddSizeForm();

  @override
  State<_AddSizeForm> createState() => _AddSizeFormState();
}

class _AddSizeFormState extends State<_AddSizeForm> {
  final _labelController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _costPriceController = TextEditingController();

  double get _price => double.tryParse(_priceController.text) ?? 0;
  double get _discountPercentage =>
      (double.tryParse(_discountPercentageController.text) ?? 0)
          .clamp(0, 100)
          .toDouble();
  double get _costPrice => double.tryParse(_costPriceController.text) ?? 0;

  @override
  void dispose() {
    _labelController.dispose();
    _priceController.dispose();
    _discountPercentageController.dispose();
    _costPriceController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final label = _labelController.text.trim();
    if (label.isEmpty || _price <= 0) return;

    context.read<AddProductViewModel>().addSize(
      label: label,
      price: _price,
      discountPercentage: _discountPercentage,
      costPrice: _costPrice > 0 ? _costPrice : null,
    );

    _labelController.clear();
    _priceController.clear();
    _discountPercentageController.clear();
    _costPriceController.clear();
    setState(() {}); // refresh the live preview back to blank
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final previewFinalPrice = ProductModel.calculateFinalPrice(
      _price,
      _discountPercentage,
    );
    final previewMargin = _costPrice > 0
        ? previewFinalPrice - _costPrice
        : null;
    final previewMarginPct = (previewMargin != null && previewFinalPrice > 0)
        ? (previewMargin / previewFinalPrice) * 100
        : null;

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
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Size label',
                hintText: 'e.g. 1 Liter, 5Kg, Dozen',
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixText: 'Rs ',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: TextField(
                    controller: _discountPercentageController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Discount',
                      suffixText: '%',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _costPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cost price (optional)',
                prefixText: 'Rs ',
                helperText: 'Used to calculate profit margin for this size',
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_price > 0) ...[
              const SizedBox(height: AppSizes.xs),
              Container(
                padding: const EdgeInsets.all(AppSizes.xs),
                decoration: BoxDecoration(
                  color: AppColors.lightContainer,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selling Price: Rs ${previewFinalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontSizeSm,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (previewMargin != null)
                      Text(
                        'Margin: Rs ${previewMargin.abs().toStringAsFixed(0)}'
                        '${previewMarginPct != null ? " (${previewMarginPct.abs().toStringAsFixed(0)}%)" : ""}',
                        style: TextStyle(
                          fontSize: AppSizes.fontSizeSm,
                          fontWeight: FontWeight.bold,
                          color: previewMargin < 0
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleAdd,
                icon: const Icon(Icons.add, color: AppColors.secondary),
                label: const Text(
                  'Add Size',
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
