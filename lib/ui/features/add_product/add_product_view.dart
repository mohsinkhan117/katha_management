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
  final _discountPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockQuantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers from the ViewModel's initial state (which
    // itself pre-filled from `existingProduct`, if any) — read once,
    // outside of build, since these are one-time seed values.
    final vm = context.read<AddProductViewModel>();
    _nameController.text = vm.name;
    _descriptionController.text = vm.description;
    _skuController.text = vm.sku;
    _categoryController.text = vm.category;
    _unitController.text = vm.unit;
    _retailPriceController.text = vm.retailPrice > 0
        ? vm.retailPrice.toStringAsFixed(0)
        : '';
    _discountPriceController.text = vm.discountPrice > 0
        ? vm.discountPrice.toStringAsFixed(0)
        : '';
    _costPriceController.text = vm.costPrice > 0
        ? vm.costPrice.toStringAsFixed(0)
        : '';
    _stockQuantityController.text = vm.stockQuantity?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _retailPriceController.dispose();
    _discountPriceController.dispose();
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
          const _SectionLabel('Pricing'),
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
                  ),
                  onChanged: (value) => context
                      .read<AddProductViewModel>()
                      .setRetailPrice(double.tryParse(value) ?? 0),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: TextField(
                  controller: _discountPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Discount price',
                  ),
                  onChanged: (value) => context
                      .read<AddProductViewModel>()
                      .setDiscountPrice(double.tryParse(value) ?? 0),
                ),
              ),
            ],
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
                    helperText: 'Used for margin reports later',
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
                      .setStockQuantity(int.tryParse(value)),
                ),
              ),
            ],
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
            subtitle: Text(
              size.discountPrice != null
                  ? 'Rs ${size.price.toStringAsFixed(0)} \u2192 Rs ${size.discountPrice!.toStringAsFixed(0)}'
                  : 'Rs ${size.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: AppSizes.fontSizeSm,
                color: AppColors.textSecondary,
              ),
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
  final _discountController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final label = _labelController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final discount = double.tryParse(_discountController.text);

    if (label.isEmpty || price <= 0) return;

    context.read<AddProductViewModel>().addSize(
      label: label,
      price: price,
      discountPrice: (discount != null && discount > 0) ? discount : null,
    );

    _labelController.clear();
    _priceController.clear();
    _discountController.clear();
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
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Size label',
                hintText: 'e.g. 250g, 1Kg, Dozen',
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
                    decoration: const InputDecoration(labelText: 'Price'),
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
                      labelText: 'Discount price',
                    ),
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
