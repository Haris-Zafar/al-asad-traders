import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/pkr_formatter.dart';
import '../models/customer_order_model.dart';
import '../providers/b2b_portal_provider.dart';

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Ledger & Statement'),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading ledger: $err')),
        data: (orders) {
          final deliveredOrders =
              orders.where((o) => o.status == OrderStatus.delivered).toList();
          final pendingOrders =
              orders.where((o) => o.status == OrderStatus.pending).toList();

          final totalDeliveredPkr = deliveredOrders.fold<int>(
            0,
            (sum, o) => sum + o.actualDeliveredTotalPkr,
          );

          return Column(
            children: [
              // Financial Summary Header Card
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Card(
                  color: AppColors.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fulfilled Purchases',
                                style: AppTextStyles.bodySmall),
                            Text(
                              PkrFormatter.format(totalDeliveredPkr),
                              style: AppTextStyles.currencyLarge,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Pending Orders', style: AppTextStyles.bodySmall),
                            Text(
                              '${pendingOrders.length} Active',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),

              // Orders History List
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: Text(
                          'No orders or ledger entries found.',
                          style: AppTextStyles.bodySmall,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final isDelivered =
                              order.status == OrderStatus.delivered;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order #${order.id}',
                                        style: AppTextStyles.titleSmall,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDelivered
                                              ? AppColors.successLight
                                              : AppColors.warningLight,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          order.status
                                              .toFormattedString()
                                              .toUpperCase(),
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                            color: isDelivered
                                                ? AppColors.success
                                                : AppColors.warning,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Date: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Items: ${order.requestedItems.length} products requested',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  const Divider(height: 16),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total Amount (PKR):',
                                          style: AppTextStyles.bodySmall),
                                      Text(
                                        PkrFormatter.format(isDelivered
                                            ? order.actualDeliveredTotalPkr
                                            : order.estimatedTotalPkr),
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                          color: isDelivered
                                              ? AppColors.success
                                              : AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
