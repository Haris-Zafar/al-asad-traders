import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/pkr_formatter.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../models/product_model.dart';
import '../providers/inventory_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  void _showAddSupplierCostDialog(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) {
    final supplierIdController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add / Link Supplier Cost'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: supplierIdController,
                decoration: const InputDecoration(
                  labelText: 'Supplier ID / Name',
                  hintText: 'e.g. supp_01 or National Mills',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Purchase Cost (PKR)',
                  hintText: '1020',
                  prefixText: 'Rs. ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final supplierId = supplierIdController.text.trim();
                final costPkr = PkrFormatter.parsePkr(costController.text);

                if (supplierId.isNotEmpty && costPkr != null && costPkr >= 0) {
                  Navigator.pop(dialogContext);
                  ref
                      .read(inventoryControllerProvider.notifier)
                      .addOrUpdateSupplierCost(
                        productId: product.id,
                        supplierId: supplierId,
                        costPkr: costPkr,
                      );
                  ref.invalidate(productDetailProvider(product.id));
                }
              },
              child: const Text('Save Cost'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCustomerPriceDialog(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) {
    final customerIdController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set Customer-Specific Wholesale Price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: customerIdController,
                decoration: const InputDecoration(
                  labelText: 'Customer ID / Name',
                  hintText: 'e.g. Metro Supermarket',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Custom Wholesale Price (PKR)',
                  hintText: '1180',
                  prefixText: 'Rs. ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final customerId = customerIdController.text.trim();
                final pricePkr = PkrFormatter.parsePkr(priceController.text);

                if (customerId.isNotEmpty && pricePkr != null && pricePkr >= 0) {
                  Navigator.pop(dialogContext);
                  ref
                      .read(inventoryControllerProvider.notifier)
                      .setCustomerPrice(
                        productId: product.id,
                        customerId: customerId,
                        pricePkr: pricePkr,
                      );
                  ref.invalidate(productDetailProvider(product.id));
                }
              },
              child: const Text('Save Custom Price'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Product',
            onPressed: () {
              context.push(RoutePaths.editProductPath(productId));
            },
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              LoadingShimmer(width: double.infinity, height: 180),
              SizedBox(height: 16),
              LoadingShimmer(width: double.infinity, height: 120),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Text('Error loading product: $error'),
        ),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found.'));
          }

          final lowestCostPkr = product.lowestSupplierCostPkr;
          final sortedSuppliers = product.sortedSupplierCosts;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Overview Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 84,
                                    height: 84,
                                    color: AppColors.primaryContainer,
                                    child: product.imageUrl != null &&
                                            product.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            product.imageUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/images/placeholder_product.png',
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                              Icons.inventory_2_outlined,
                                              size: 36,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: AppTextStyles.titleLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Barcode: ${product.barcode.isNotEmpty ? product.barcode : 'None'}',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      if (product.note.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Note: ${product.note}',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),

                                      // Archive Toggle
                                      Row(
                                        children: [
                                          Text(
                                            'Status: ',
                                            style: AppTextStyles.bodySmall,
                                          ),
                                          Switch(
                                            value: !product.isArchived,
                                            onChanged: (active) {
                                              ref
                                                  .read(
                                                      inventoryControllerProvider
                                                          .notifier)
                                                  .toggleArchiveProduct(
                                                      product.id,
                                                      product.isArchived);
                                              ref.invalidate(
                                                  productDetailProvider(
                                                      product.id));
                                            },
                                          ),
                                          Text(
                                            product.isArchived
                                                ? 'Archived'
                                                : 'Active',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                              color: product.isArchived
                                                  ? AppColors.textMuted
                                                  : AppColors.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pricing & Stock Details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pricing & Inventory Summary',
                              style: AppTextStyles.titleMedium,
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Default Wholesale',
                                        style: AppTextStyles.bodySmall),
                                    Text(
                                      PkrFormatter.format(
                                          product.defaultWholesalePricePkr),
                                      style: AppTextStyles.currencyLarge,
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Retail Price',
                                        style: AppTextStyles.bodySmall),
                                    Text(
                                      PkrFormatter.format(
                                          product.retailPricePkr),
                                      style: AppTextStyles.titleLarge,
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Current Stock',
                                        style: AppTextStyles.bodySmall),
                                    Text(
                                      '${product.currentStock} units',
                                      style: AppTextStyles.titleLarge.copyWith(
                                        color: product.isLowStock
                                            ? AppColors.warning
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Supplier Costs Card (Sorted with MINIMUM COST ON TOP)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Linked Supplier Costs',
                                  style: AppTextStyles.titleMedium,
                                ),
                                TextButton.icon(
                                  onPressed: () => _showAddSupplierCostDialog(
                                    context,
                                    ref,
                                    product,
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Supplier Cost'),
                                ),
                              ],
                            ),
                            const Divider(height: 16),

                            if (sortedSuppliers.isEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'No supplier costs recorded yet.',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                            ] else ...[
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sortedSuppliers.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 8),
                                itemBuilder: (context, index) {
                                  final entry = sortedSuppliers[index];
                                  final supplierId = entry.key;
                                  final costPkr = entry.value;
                                  final isLowest = index == 0 || costPkr == lowestCostPkr;

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      supplierId,
                                      style: AppTextStyles.titleSmall,
                                    ),
                                    subtitle: isLowest
                                        ? Text(
                                            'Minimum Cost Option',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          PkrFormatter.format(costPkr),
                                          style: AppTextStyles.titleMedium
                                              .copyWith(
                                            color: isLowest
                                                ? AppColors.success
                                                : AppColors.textPrimary,
                                            fontWeight: isLowest
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: AppColors.error,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(
                                                    inventoryControllerProvider
                                                        .notifier)
                                                .removeSupplierCost(
                                                  productId: product.id,
                                                  supplierId: supplierId,
                                                );
                                            ref.invalidate(
                                                productDetailProvider(
                                                    product.id));
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Customer-Specific Wholesale Prices Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Customer-Specific Wholesale Prices',
                                  style: AppTextStyles.titleMedium,
                                ),
                                TextButton.icon(
                                  onPressed: () => _showAddCustomerPriceDialog(
                                    context,
                                    ref,
                                    product,
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Custom Price'),
                                ),
                              ],
                            ),
                            const Divider(height: 16),

                            if (product.customerPrices.isEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'No customer-specific prices configured. Default wholesale price (${PkrFormatter.format(product.defaultWholesalePricePkr)}) applies.',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                            ] else ...[
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: product.customerPrices.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 8),
                                itemBuilder: (context, index) {
                                  final custId = product.customerPrices.keys
                                      .elementAt(index);
                                  final customPricePkr =
                                      product.customerPrices[custId]!;

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      custId,
                                      style: AppTextStyles.titleSmall,
                                    ),
                                    trailing: Text(
                                      PkrFormatter.format(customPricePkr),
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
