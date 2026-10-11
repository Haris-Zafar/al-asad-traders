import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inventory/providers/inventory_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Banner
            userAsync.when(
              data: (user) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${user?.name ?? 'Admin'}!',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: AppColors.textOnPrimary,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Al Asad Traders Wholesale Operations Dashboard',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.analytics_rounded,
                      size: 48,
                      color: AppColors.textOnPrimary,
                    ),
                  ],
                ),
              ),
              loading: () => Container(
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.push(RoutePaths.createInvoice);
                  },
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Create New Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(180, 48),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push(RoutePaths.addProduct);
                  },
                  icon: const Icon(Icons.add_box_rounded),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(160, 48),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    context.push(RoutePaths.purchaseList);
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Purchase List'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(160, 48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // KPI Summary Cards Grid
            Text(
              'Business Overview',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 12),

            productsAsync.when(
              data: (products) {
                final totalProducts = products.length;
                final lowStockCount =
                    products.where((p) => p.isLowStock && !p.isArchived).length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 800
                        ? 4
                        : (constraints.maxWidth > 500 ? 2 : 1);

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.6,
                      children: [
                        _DashboardKpiCard(
                          title: 'Total Catalog Products',
                          value: '$totalProducts items',
                          icon: Icons.inventory_2_rounded,
                          color: AppColors.primary,
                          onTap: () => context.go(RoutePaths.inventory),
                        ),
                        _DashboardKpiCard(
                          title: 'Low Stock Alerts',
                          value: '$lowStockCount items',
                          icon: Icons.warning_amber_rounded,
                          color: lowStockCount > 0
                              ? AppColors.warning
                              : AppColors.success,
                          onTap: () {
                            context.go(RoutePaths.inventory);
                          },
                        ),
                        _DashboardKpiCard(
                          title: 'Billing & Invoices',
                          value: 'Create Invoice',
                          icon: Icons.receipt_long_rounded,
                          color: AppColors.success,
                          onTap: () => context.go(RoutePaths.invoices),
                        ),
                        _DashboardKpiCard(
                          title: 'Suppliers Directory',
                          value: 'View Suppliers',
                          icon: Icons.local_shipping_rounded,
                          color: AppColors.primaryLight,
                          onTap: () => context.go(RoutePaths.suppliers),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, __) => Text('Error loading summary: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelSmall,
                  ),
                  Icon(icon, color: color, size: 24),
                ],
              ),
              Text(
                value,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
