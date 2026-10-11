import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/pkr_formatter.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../providers/invoice_provider.dart';
import '../widgets/scanner_modal.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scanBarcode() {
    ScannerModal.show(
      context,
      onBarcodeScanned: (barcode) async {
        final service = ref.read(inventoryFirestoreServiceProvider);
        final product = await service.getProductByBarcode(barcode);
        if (product != null) {
          ref.read(invoiceBuilderProvider.notifier).addProductToCart(product);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "${product.name}" to invoice cart.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No product found with barcode "$barcode".'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
      },
    );
  }

  void _handleCompleteInvoice() async {
    final notifier = ref.read(invoiceBuilderProvider.notifier);
    final invoiceId = await notifier.submitInvoice();

    if (mounted && invoiceId != null) {
      final invoice = await ref.read(invoiceDetailProvider(invoiceId).future);
      notifier.clearCart();

      if (mounted && invoice != null) {
        // Show Success Dialog with Direct PDF Print & WhatsApp Share Actions
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 28),
                const SizedBox(width: 8),
                const Text('Invoice Created'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice #${invoice.id} for ${invoice.customerName} has been saved.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Grand Total: ${PkrFormatter.format(invoice.grandTotalPkr)}',
                  style: AppTextStyles.currencyLarge,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go(RoutePaths.invoices);
                },
                child: const Text('Back to Invoices'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await PdfInvoiceService.shareInvoicePdf(invoice);
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('WhatsApp Share'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await PdfInvoiceService.printInvoice(invoice);
                },
                icon: const Icon(Icons.print_rounded),
                label: const Text('Print PDF'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(invoiceBuilderProvider);
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Invoice'),
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                ref.read(invoiceBuilderProvider.notifier).clearCart();
              },
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: AppColors.textOnPrimary),
              label: const Text(
                'Clear Cart',
                style: TextStyle(color: AppColors.textOnPrimary),
              ),
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Section: Product Selector & Barcode Scanner
          Expanded(
            flex: 5,
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catalog Lookup', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            ref
                                .read(inventorySearchQueryProvider.notifier)
                                .state = val;
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search catalog by name or barcode...',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        tooltip: 'Scan Barcode',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Products Grid / List
                  Expanded(
                    child: productsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, _) => Text('Error loading products: $err'),
                      data: (products) {
                        final activeProducts =
                            products.where((p) => !p.isArchived).toList();

                        if (activeProducts.isEmpty) {
                          return const Center(
                            child: Text('No active products found in catalog.'),
                          );
                        }

                        return ListView.separated(
                          itemCount: activeProducts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final product = activeProducts[index];
                            final pricePkr =
                                product.getWholesalePriceForCustomer(
                                    cartState.customerId);

                            return Card(
                              child: ListTile(
                                title: Text(product.name,
                                    style: AppTextStyles.titleSmall),
                                subtitle: Text(
                                  'Stock: ${product.currentStock} units | Barcode: ${product.barcode}',
                                  style: AppTextStyles.bodySmall,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      PkrFormatter.format(pricePkr),
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton.filled(
                                      onPressed: () {
                                        ref
                                            .read(invoiceBuilderProvider.notifier)
                                            .addProductToCart(product);
                                      },
                                      icon: const Icon(Icons.add_shopping_cart,
                                          size: 18),
                                      tooltip: 'Add to Invoice',
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
            ),
          ),
          const VerticalDivider(width: 1),

          // Right Section: Invoice Cart & Summary
          Expanded(
            flex: 6,
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Invoice Summary', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),

                  // Customer Name Input
                  TextFormField(
                    initialValue: cartState.customerName,
                    onChanged: (val) {
                      ref.read(invoiceBuilderProvider.notifier).setCustomer(
                            id: cartState.customerId,
                            name: val.trim().isNotEmpty
                                ? val.trim()
                                : 'Walk-in Customer',
                          );
                    },
                    decoration: const InputDecoration(
                      labelText: 'Customer Name / Supermarket',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cart Items Table
                  Expanded(
                    child: cartState.items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 48,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Invoice cart is empty',
                                  style: AppTextStyles.titleSmall,
                                ),
                                Text(
                                  'Select products or scan barcodes to add items.',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: cartState.items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = cartState.items[index];

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item.productName,
                                              style: AppTextStyles.titleSmall),
                                          Text(
                                            '${PkrFormatter.format(item.unitPricePkr)} / unit',
                                            style: AppTextStyles.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quantity Counter
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 20),
                                          onPressed: () {
                                            ref
                                                .read(invoiceBuilderProvider
                                                    .notifier)
                                                .updateQuantity(
                                                  item.productId,
                                                  item.quantity - 1,
                                                );
                                          },
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: AppTextStyles.titleMedium,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 20),
                                          onPressed: () {
                                            ref
                                                .read(invoiceBuilderProvider
                                                    .notifier)
                                                .updateQuantity(
                                                  item.productId,
                                                  item.quantity + 1,
                                                );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),

                                    // Subtotal PKR
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        PkrFormatter.format(item.subtotalPkr),
                                        style: AppTextStyles.titleSmall.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded,
                                          size: 18, color: AppColors.error),
                                      onPressed: () {
                                        ref
                                            .read(
                                                invoiceBuilderProvider.notifier)
                                            .removeItem(item.productId);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Grand Total PKR Summary Card
                  Card(
                    color: AppColors.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand Total:', style: AppTextStyles.titleLarge),
                          Text(
                            PkrFormatter.format(cartState.grandTotalPkr),
                            style: AppTextStyles.displayMedium.copyWith(
                              color: AppColors.success,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Complete Invoice Button
                  ElevatedButton.icon(
                    onPressed: cartState.items.isEmpty || cartState.isLoading
                        ? null
                        : _handleCompleteInvoice,
                    icon: cartState.isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.receipt_long_rounded),
                    label: cartState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.textOnPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Complete & Generate PKR Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
