import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/pkr_formatter.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../providers/invoice_provider.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(invoiceId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #$invoiceId'),
        actions: [
          invoiceAsync.maybeWhen(
            data: (invoice) => invoice != null
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        tooltip: 'Share via WhatsApp',
                        onPressed: () {
                          PdfInvoiceService.shareInvoicePdf(invoice);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.print_rounded),
                        tooltip: 'Print PDF',
                        onPressed: () {
                          PdfInvoiceService.printInvoice(invoice);
                        },
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: invoiceAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              LoadingShimmer(width: double.infinity, height: 120),
              SizedBox(height: 16),
              LoadingShimmer(width: double.infinity, height: 200),
            ],
          ),
        ),
        error: (err, _) => Center(child: Text('Error loading invoice: $err')),
        data: (invoice) {
          if (invoice == null) {
            return const Center(child: Text('Invoice not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Invoice Overview Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Billed Customer',
                                        style: AppTextStyles.bodySmall),
                                    Text(
                                      invoice.customerName,
                                      style: AppTextStyles.titleLarge,
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Date',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                    Text(
                                      '${invoice.createdAt.day}/${invoice.createdAt.month}/${invoice.createdAt.year}',
                                      style: AppTextStyles.titleSmall,
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

                    // Itemized Table Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Itemized PKR Breakdown',
                                style: AppTextStyles.titleMedium),
                            const Divider(height: 20),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: invoice.items.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 12),
                              itemBuilder: (context, index) {
                                final item = invoice.items[index];

                                return Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item.productName,
                                              style: AppTextStyles.titleSmall),
                                          Text(
                                            '${PkrFormatter.format(item.unitPricePkr)} × ${item.quantity}',
                                            style: AppTextStyles.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      PkrFormatter.format(item.subtotalPkr),
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total & Actions
                    Card(
                      color: AppColors.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Grand Total:', style: AppTextStyles.titleLarge),
                            Text(
                              PkrFormatter.format(invoice.grandTotalPkr),
                              style: AppTextStyles.currencyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              PdfInvoiceService.shareInvoicePdf(invoice);
                            },
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('WhatsApp Share'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              PdfInvoiceService.printInvoice(invoice);
                            },
                            icon: const Icon(Icons.print_rounded),
                            label: const Text('Print PDF'),
                          ),
                        ),
                      ],
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
