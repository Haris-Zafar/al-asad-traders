import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/pkr_formatter.dart';
import '../providers/supplier_provider.dart';

class PurchaseListScreen extends ConsumerWidget {
  const PurchaseListScreen({super.key});

  void _sharePurchaseListViaWhatsApp(BuildContext context, WidgetRef ref) {
    final requirements = ref.read(purchaseRequirementsProvider);
    final totalBudget = ref.read(totalPurchaseRequirementBudgetPkrProvider);

    final buffer = StringBuffer();
    buffer.writeln('*AL ASAD TRADERS - PURCHASE REQUIREMENT ORDER SHEET*');
    buffer.writeln('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln('-----------------------------------');

    for (final req in requirements) {
      buffer.writeln('• *${req.product.name}*');
      buffer.writeln('  Deficit Qty: ${req.requiredStock} units');
      if (req.cheapestSupplierName != null) {
        buffer.writeln(
            '  Best Supplier: ${req.cheapestSupplierName} @ ${PkrFormatter.format(req.cheapestCostPkr ?? 0)}');
      }
      buffer.writeln('  Est. Total: ${PkrFormatter.format(req.totalEstimatedCostPkr)}');
      buffer.writeln('');
    }

    buffer.writeln('-----------------------------------');
    buffer.writeln('*Total Estimated Purchase Budget: ${PkrFormatter.format(totalBudget)}*');

    Share.share(
      buffer.toString(),
      subject: 'Al Asad Traders - Purchase Order Sheet',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirements = ref.watch(purchaseRequirementsProvider);
    final totalBudgetPkr = ref.watch(totalPurchaseRequirementBudgetPkrProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automated Purchase Requirement List'),
      ),
      body: requirements.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 64,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All Stocks Sufficient!',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No low-stock items require replenishment at this time.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Total Estimated Budget Card
                Container(
                  width: double.infinity,
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
                              Text('Total Low-Stock Items',
                                  style: AppTextStyles.bodySmall),
                              Text(
                                '${requirements.length} Products Deficient',
                                style: AppTextStyles.titleMedium,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Est. Purchase Budget',
                                  style: AppTextStyles.bodySmall),
                              Text(
                                PkrFormatter.format(totalBudgetPkr),
                                style: AppTextStyles.currencyLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),

                // Deficient Items List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: requirements.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final req = requirements[index];

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
                                  Expanded(
                                    child: Text(
                                      req.product.name,
                                      style: AppTextStyles.titleMedium,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Deficit: ${req.requiredStock} units',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Best Supplier Option',
                                          style: AppTextStyles.bodySmall),
                                      Text(
                                        req.cheapestSupplierName ??
                                            'No Supplier Linked',
                                        style: AppTextStyles.titleSmall.copyWith(
                                          color: req.cheapestSupplierName != null
                                              ? AppColors.success
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Estimated Cost (PKR)',
                                          style: AppTextStyles.bodySmall),
                                      Text(
                                        PkrFormatter.format(
                                            req.totalEstimatedCostPkr),
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
            ),
      bottomNavigationBar: requirements.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: ElevatedButton.icon(
                onPressed: () => _sharePurchaseListViaWhatsApp(context, ref),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Purchase Sheet via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
    );
  }
}
