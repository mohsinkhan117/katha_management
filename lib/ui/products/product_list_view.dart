// lib/ui/products/product_list_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:katha_management/core/constants/sizes/sizes.dart';
import 'package:katha_management/core/models/product/product_model.dart';
import 'package:katha_management/core/theme/app_colors/app_colors.dart';
import 'package:katha_management/ui/features/add_product/add_product_view.dart';
import 'product_list_view_model.dart';

class ProductListView extends StatelessWidget {
  static const String routeName = '/product-list-view';
  static Route route() {
    return MaterialPageRoute(
      builder: (context) => const ProductListView(),
      settings: const RouteSettings(name: routeName),
    );
  }

  const ProductListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductListViewModel(),
      child: const _ProductListViewBody(),
    );
  }
}

class _ProductListViewBody extends StatelessWidget {
  const _ProductListViewBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductListViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by name or SKU',
                ),
                onChanged: (value) =>
                    context.read<ProductListViewModel>().setSearchQuery(value),
              ),
            ),
            if (vm.categories.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSizes.sm),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: vm.categoryFilter == null,
                        onSelected: (_) => context
                            .read<ProductListViewModel>()
                            .setCategoryFilter(null),
                      ),
                    ),
                    ...vm.categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: AppSizes.sm),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: vm.categoryFilter == category,
                          onSelected: (_) => context
                              .read<ProductListViewModel>()
                              .setCategoryFilter(category),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSizes.sm),
            if (vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            Expanded(
              child: vm.isLoading && vm.products.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : vm.products.isEmpty
                  ? const Center(
                      child: Text(
                        'No products yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                      ),
                      itemCount: vm.products.length,
                      itemBuilder: (context, index) =>
                          _ProductTile(product: vm.products[index]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(AddProductView.route());
          if (context.mounted) {
            context.read<ProductListViewModel>().refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final statusColor = product.status == ProductStatus.inStock
        ? AppColors.success
        : AppColors.error;

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
        onTap: () async {
          await Navigator.of(
            context,
          ).push(AddProductView.route(existingProduct: product));
          if (context.mounted) {
            context.read<ProductListViewModel>().refresh();
          }
        },
        leading: CircleAvatar(
          backgroundColor: AppColors.lightContainer,
          child: Text(
            product.name.isNotEmpty ? product.name[0] : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          product.hasSizes
              ? '${product.sizes.length} size${product.sizes.length == 1 ? '' : 's'}'
              : product.hasDiscount
              ? 'Rs ${product.finalPrice.toStringAsFixed(0)} '
                    '(${product.discountPercentage.toStringAsFixed(0)}% off Rs ${product.retailPrice.toStringAsFixed(0)})'
              : 'Rs ${product.finalPrice.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: AppSizes.fontSizeSm,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: Text(
                product.status.label,
                style: TextStyle(
                  fontSize: AppSizes.fontSizeSm,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (product.isLowStock) ...[
              const SizedBox(height: AppSizes.xs),
              const Text(
                'Low stock',
                style: TextStyle(
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
