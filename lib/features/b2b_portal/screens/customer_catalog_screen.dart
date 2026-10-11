import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/pkr_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../providers/b2b_portal_provider.dart';

class CustomerCatalogScreen extends ConsumerWidget {
  const CustomerCatalogScreen({super.key});

  void _showOrderCartModal(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserModelProvider).asData?.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Consumer(
          builder: (context, ref, _) {
            final cart = ref.watch(customerCartProvider);

            return Container(
              height: 520,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('B2B Order Cart', style: AppTextStyles.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Estimated Price Warning Note (Requirement 6.2)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Notice: Estimated prices shown. Final invoice total will be calculated upon order dispatch.',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cart Items
                  Expanded(
                    child: cart.items.isEmpty
                        ? Center(
                            child: Text(
                              'Cart is empty. Select products from catalog.',
                              style: AppTextStyles.bodySmall,
                            ),
                          )
                        : ListView.separated(
                            itemCount: cart.items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = cart.items[index];

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.productName,
                                    style: AppTextStyles.titleSmall),
                                subtitle: Text(
                                  'Est. Unit Price: ${PkrFormatter.format(item.estimatedPricePkr)}',
                                  style: AppTextStyles.bodySmall,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 18),
                                      onPressed: () {
                                        ref
                                            .read(
                                                customerCartProvider.notifier)
                                            .updateQuantity(item.productId,
                                                item.quantity - 1);
                                      },
                                    ),
                                    Text('${item.quantity}',
                                        style: AppTextStyles.titleSmall),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          size: 18),
                                      onPressed: () {
                                        ref
                                            .read(
                                                customerCartProvider.notifier)
                                            .updateQuantity(item.productId,
                                                item.quantity + 1);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      PkrFormatter.format(item.subtotalPkr),
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Grand Total
                  Card(
                    color: AppColors.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Estimated Total:',
                              style: AppTextStyles.titleMedium),
                          Text(
                            PkrFormatter.format(cart.estimatedTotalPkr),
                            style: AppTextStyles.currencyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Place Order Button
                  ElevatedButton(
                    onPressed: cart.items.isEmpty || user == null
                        ? null
                        : () async {
                            Navigator.pop(modalContext);
                            final orderId = await ref
                                .read(b2bPortalControllerProvider.notifier)
                                .placeOrderRequest(
                                  customerId: user.id,
                                  customerName: user.name,
                                  items: cart.items,
                                );

                            if (orderId != null) {
                              ref
                                  .read(customerCartProvider.notifier)
                                  .clearCart();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'B2B Order request submitted successfully!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          },
                    child: const Text('Submit Order Request'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final user = ref.watch(currentUserModelProvider).asData?.value;
    final cart = ref.watch(customerCartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wholesale Product Catalog'),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading catalog: $err')),
        data: (products) {
          final activeProducts =
              products.where((p) => !p.isArchived).toList();

          if (activeProducts.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisExtent: 240,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: activeProducts.length,
            itemBuilder: (context, index) {
              final product = activeProducts[index];
              final customWholesalePkr =
                  product.getWholesalePriceForCustomer(user?.id);

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: AppColors.primaryContainer,
                        child: product.imageUrl != null &&
                                product.imageUrl!.isNotEmpty
                            ? Image.network(product.imageUrl!,
                                fit: BoxFit.cover)
                            : Image.asset(
                                'assets/images/placeholder_product.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: AppTextStyles.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                PkrFormatter.format(customWholesalePkr),
                                style: AppTextStyles.currencyMedium.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                              IconButton.filled(
                                onPressed: () {
                                  ref
                                      .read(customerCartProvider.notifier)
                                      .addItem(product, user?.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Added "${product.name}" to cart'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add, size: 18),
                                tooltip: 'Add to Order',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: cart.items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showOrderCartModal(context, ref),
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textOnPrimary,
              icon: const Icon(Icons.shopping_cart_rounded),
              label: Text(
                'Cart (${cart.items.length}) • ${PkrFormatter.format(cart.estimatedTotalPkr)}',
              ),
            ),
    );
  }
}
