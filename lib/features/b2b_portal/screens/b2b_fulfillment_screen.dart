import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/pkr_formatter.dart';
import '../../invoices/models/invoice_item_snapshot.dart';
import '../../invoices/providers/invoice_provider.dart';
import '../models/customer_order_model.dart';
import '../providers/b2b_portal_provider.dart';

class B2bFulfillmentScreen extends ConsumerWidget {
  const B2bFulfillmentScreen({super.key});

  void _showFulfillmentModal(
    BuildContext context,
    WidgetRef ref,
    CustomerOrderModel order,
  ) {
    final noteController = TextEditingController(text: order.adjustmentNote);
    final itemQuantities = <String, int>{};

    for (final item in order.requestedItems) {
      itemQuantities[item.productId] = item.quantity;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int calculateDeliveredTotalPkr() {
              return order.requestedItems.fold<int>(0, (sum, item) {
                final qty = itemQuantities[item.productId] ?? item.quantity;
                return sum + (item.estimatedPricePkr * qty);
              });
            }

            return Container(
              height: 580,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Fulfill Order #${order.id}',
                          style: AppTextStyles.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  Text('Customer: ${order.customerName}',
                      style: AppTextStyles.bodySmall),
                  const Divider(height: 20),

                  Text('Adjust Delivered Quantities:',
                      style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),

                  // Items List with Quantity Controls
                  Expanded(
                    child: ListView.separated(
                      itemCount: order.requestedItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = order.requestedItems[index];
                        final currentQty =
                            itemQuantities[item.productId] ?? item.quantity;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.productName,
                              style: AppTextStyles.titleSmall),
                          subtitle: Text(
                            'Unit Price: ${PkrFormatter.format(item.estimatedPricePkr)}',
                            style: AppTextStyles.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 20),
                                onPressed: () {
                                  if (currentQty > 0) {
                                    setModalState(() {
                                      itemQuantities[item.productId] =
                                          currentQty - 1;
                                    });
                                  }
                                },
                              ),
                              Text('$currentQty', style: AppTextStyles.titleSmall),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 20),
                                onPressed: () {
                                  setModalState(() {
                                    itemQuantities[item.productId] =
                                        currentQty + 1;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                PkrFormatter.format(
                                    item.estimatedPricePkr * currentQty),
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

                  // Dispatch Note Input
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Adjustment / Dispatch Note (Optional)',
                      hintText: 'e.g. Full order dispatched as requested.',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Total Card
                  Card(
                    color: AppColors.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Actual Total (PKR):',
                              style: AppTextStyles.titleMedium),
                          Text(
                            PkrFormatter.format(calculateDeliveredTotalPkr()),
                            style: AppTextStyles.currencyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fulfill & Convert to Invoice Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(modalContext);

                      final actualSnapshots = order.requestedItems.map((item) {
                        final qty =
                            itemQuantities[item.productId] ?? item.quantity;
                        return InvoiceItemSnapshot(
                          productId: item.productId,
                          productName: item.productName,
                          unitPricePkr: item.estimatedPricePkr,
                          purchaseCostPkr: 0,
                          quantity: qty,
                          subtotalPkr: item.estimatedPricePkr * qty,
                        );
                      }).toList();

                      final invoiceId = await ref
                          .read(b2bPortalControllerProvider.notifier)
                          .convertOrderToInvoice(
                            order: order,
                            actualItems: actualSnapshots,
                            adjustmentNote: noteController.text,
                          );

                      if (invoiceId != null && context.mounted) {
                        final invoice = await ref.read(
                            invoiceDetailProvider(invoiceId).future);

                        if (context.mounted && invoice != null) {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Order Fulfilled & Converted!'),
                              content: Text(
                                'Invoice #${invoice.id} created for ${invoice.customerName}.\nGrand Total: ${PkrFormatter.format(invoice.grandTotalPkr)}',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Done'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    PdfInvoiceService.shareInvoicePdf(invoice);
                                  },
                                  icon: const Icon(Icons.share_rounded),
                                  label: const Text('WhatsApp Share'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    PdfInvoiceService.printInvoice(invoice);
                                  },
                                  icon: const Icon(Icons.print_rounded),
                                  label: const Text('Print PDF'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Fulfill & Convert to PKR Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size.fromHeight(48),
                    ),
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
    final ordersAsync = ref.watch(allOrdersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('B2B Order Fulfillment Portal'),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading orders: $err')),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Text(
                'No incoming B2B orders to fulfill.',
                style: AppTextStyles.bodySmall,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final isPending = order.status == OrderStatus.pending;

              return Card(
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
                              Text(
                                order.customerName,
                                style: AppTextStyles.titleMedium,
                              ),
                              Text(
                                'Order #${order.id} • ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPending
                                  ? AppColors.warningLight
                                  : AppColors.successLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.status.toFormattedString().toUpperCase(),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isPending
                                    ? AppColors.warning
                                    : AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),

                      Text(
                        'Requested Items: ${order.requestedItems.length} products (${PkrFormatter.format(order.estimatedTotalPkr)})',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 12),

                      if (isPending)
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showFulfillmentModal(context, ref, order),
                          icon: const Icon(Icons.assignment_turned_in_rounded),
                          label: const Text('Fulfill Order & Generate Invoice'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size.fromHeight(44),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
