import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/pkr_formatter.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../providers/invoice_provider.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices & Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create New Invoice',
            onPressed: () {
              context.push(RoutePaths.createInvoice);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search invoices by customer name or ID...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          const Divider(),

          // Invoices List
          Expanded(
            child: invoicesAsync.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const LoadingShimmer(
                  width: double.infinity,
                  height: 90,
                  borderRadius: 12,
                ),
              ),
              error: (err, _) => Center(
                child: Text('Error loading invoices: $err'),
              ),
              data: (invoices) {
                final filteredInvoices = invoices.where((inv) {
                  if (_searchQuery.isEmpty) return true;
                  return inv.customerName.toLowerCase().contains(_searchQuery) ||
                      inv.id.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredInvoices.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text('No Invoices Found', style: AppTextStyles.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No invoice matches "$_searchQuery".'
                                : 'Create your first invoice for B2B billing.',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push(RoutePaths.createInvoice);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Invoice'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredInvoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final invoice = filteredInvoices[index];

                    return Card(
                      child: ListTile(
                        onTap: () {
                          context.push(RoutePaths.invoiceDetailPath(invoice.id));
                        },
                        title: Row(
                          children: [
                            Text(
                              invoice.customerName,
                              style: AppTextStyles.titleSmall,
                            ),
                            const Spacer(),
                            Text(
                              PkrFormatter.format(invoice.grandTotalPkr),
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(
                                '#${invoice.id} • ${invoice.items.length} items',
                                style: AppTextStyles.bodySmall,
                              ),
                              const Spacer(),
                              Text(
                                '${invoice.createdAt.day}/${invoice.createdAt.month}/${invoice.createdAt.year}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share_rounded,
                                  color: AppColors.primary),
                              tooltip: 'WhatsApp Share',
                              onPressed: () {
                                PdfInvoiceService.shareInvoicePdf(invoice);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.print_rounded,
                                  color: AppColors.primary),
                              tooltip: 'Print PDF',
                              onPressed: () {
                                PdfInvoiceService.printInvoice(invoice);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(RoutePaths.createInvoice);
        },
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.receipt_long_rounded),
        label: const Text('New Invoice'),
      ),
    );
  }
}
