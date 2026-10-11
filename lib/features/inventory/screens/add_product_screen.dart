import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/pkr_formatter.dart';
import '../../customers/providers/customer_provider.dart';
import '../../suppliers/providers/supplier_provider.dart';
import '../models/product_model.dart';
import '../providers/inventory_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AddProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _defaultCostPriceController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _noteController = TextEditingController();

  Map<String, int> _supplierCosts = {};
  Map<String, int> _customerPrices = {};

  String? _existingImageUrl;
  bool _isInitialLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _wholesalePriceController.dispose();
    _defaultCostPriceController.dispose();
    _retailPriceController.dispose();
    _stockController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _populateExistingData(ProductModel product) {
    if (!_isInitialLoaded) {
      _nameController.text = product.name;
      _barcodeController.text = product.barcode;
      _wholesalePriceController.text =
          product.defaultWholesalePricePkr.toString();
      _defaultCostPriceController.text =
          product.defaultCostPricePkr.toString();
      _retailPriceController.text = product.retailPricePkr.toString();
      _stockController.text = product.currentStock.toString();
      _noteController.text = product.note;
      _supplierCosts = Map<String, int>.from(product.supplierCosts);
      _customerPrices = Map<String, int>.from(product.customerPrices);
      _existingImageUrl = product.imageUrl;
      _isInitialLoaded = true;
    }
  }

  void _scanBarcodeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scan Product Barcode',
                    style: AppTextStyles.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                        final scannedCode = barcodes.first.rawValue!;
                        setState(() {
                          _barcodeController.text = scannedCode;
                        });
                        Navigator.pop(modalContext);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddSupplierCostDialog() {
    final suppliersAsync = ref.read(suppliersStreamProvider);
    final costController = TextEditingController();
    String? selectedSupplier;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Supplier Specific Cost'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              suppliersAsync.when(
                data: (suppliers) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Supplier',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                    items: suppliers.map((s) {
                      return DropdownMenuItem(value: s.name, child: Text(s.name));
                    }).toList(),
                    onChanged: (val) => selectedSupplier = val,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => TextField(
                  onChanged: (val) => selectedSupplier = val,
                  decoration: const InputDecoration(
                    labelText: 'Supplier Name',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Purchase Cost (PKR)',
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
                final costPkr = PkrFormatter.parsePkr(costController.text);
                if (selectedSupplier != null &&
                    selectedSupplier!.isNotEmpty &&
                    costPkr != null &&
                    costPkr >= 0) {
                  setState(() {
                    _supplierCosts[selectedSupplier!] = costPkr;
                  });
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add Cost'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCustomerPriceDialog() {
    final customersAsync = ref.read(customersStreamProvider);
    final priceController = TextEditingController();
    String? selectedCustomer;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Customer Specific Wholesale Price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              customersAsync.when(
                data: (customers) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select B2B Customer',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    items: customers.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) => selectedCustomer = val,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => TextField(
                  onChanged: (val) => selectedCustomer = val,
                  decoration: const InputDecoration(
                    labelText: 'Customer ID / Name',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Custom Price (PKR)',
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
                final pricePkr = PkrFormatter.parsePkr(priceController.text);
                if (selectedCustomer != null &&
                    selectedCustomer!.isNotEmpty &&
                    pricePkr != null &&
                    pricePkr >= 0) {
                  setState(() {
                    _customerPrices[selectedCustomer!] = pricePkr;
                  });
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add Price'),
            ),
          ],
        );
      },
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final wholesalePkr =
          PkrFormatter.parsePkr(_wholesalePriceController.text) ?? 0;
      final defaultCostPkr =
          PkrFormatter.parsePkr(_defaultCostPriceController.text) ?? 0;
      final retailPkr =
          PkrFormatter.parsePkr(_retailPriceController.text) ?? 0;
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;

      final success = await ref
          .read(inventoryControllerProvider.notifier)
          .saveProduct(
            existingId: widget.productId,
            name: _nameController.text,
            barcode: _barcodeController.text,
            defaultWholesalePricePkr: wholesalePkr,
            defaultCostPricePkr: defaultCostPkr,
            retailPricePkr: retailPkr,
            currentStock: stock,
            note: _noteController.text,
            supplierCosts: _supplierCosts,
            customerPrices: _customerPrices,
            existingImageUrl: _existingImageUrl,
          );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.productId == null
                ? 'Product added to catalog'
                : 'Product updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryControllerProvider);
    final isEditing = widget.productId != null;

    if (isEditing) {
      final productAsync = ref.watch(productDetailProvider(widget.productId!));
      productAsync.whenData((product) {
        if (product != null) {
          _populateExistingData(product);
        }
      });
    }

    // Sorted supplier costs with minimum cost on top
    final sortedSupplierEntries = _supplierCosts.entries.toList();
    sortedSupplierEntries.sort((a, b) => a.value.compareTo(b.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error Banner
                  if (state.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Section 1: General Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1. General Information',
                              style: AppTextStyles.titleMedium),
                          const Divider(height: 20),

                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Product Name *',
                              hintText: 'e.g. Basmati Rice 5kg',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter product name'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _barcodeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Barcode / SKU',
                                    hintText: '8901234567890',
                                    prefixIcon: Icon(Icons.qr_code_2_rounded),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                onPressed: _scanBarcodeModal,
                                icon: const Icon(Icons.qr_code_scanner_rounded),
                                tooltip: 'Scan Barcode',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _noteController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Product Note / Description (Optional)',
                              hintText: 'e.g. Super Kernel 2026 Batch, Premium Bag',
                              prefixIcon: Icon(Icons.note_alt_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 2: Standard Pricing & Stock
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('2. Pricing & Stock Units',
                              style: AppTextStyles.titleMedium),
                          const Divider(height: 20),

                          TextFormField(
                            controller: _wholesalePriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Default Wholesale Price (PKR) *',
                              hintText: '1200',
                              prefixText: 'Rs. ',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter default wholesale price'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _defaultCostPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Default Purchase Cost (PKR)',
                              hintText: '1000',
                              prefixText: 'Rs. ',
                              prefixIcon: Icon(Icons.shopping_cart_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _retailPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Retail Price (PKR) *',
                              hintText: '1400',
                              prefixText: 'Rs. ',
                              prefixIcon: Icon(Icons.price_change_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter retail price'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Available Stock Quantity (Units) *',
                              hintText: '150',
                              prefixIcon: Icon(Icons.format_list_numbered_rounded),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter stock quantity'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 3: Supplier-Specific Costs (Minimum on top)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('3. Supplier Purchase Costs',
                                  style: AppTextStyles.titleMedium),
                              TextButton.icon(
                                onPressed: _showAddSupplierCostDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Cost'),
                              ),
                            ],
                          ),
                          Text(
                            'Recorded supplier costs (Minimum cost highlighted on top):',
                            style: AppTextStyles.bodySmall,
                          ),
                          const Divider(height: 16),

                          if (sortedSupplierEntries.isEmpty) ...[
                            Text('No supplier specific costs added yet.',
                                style: AppTextStyles.bodySmall),
                          ] else ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedSupplierEntries.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 8),
                              itemBuilder: (context, index) {
                                final entry = sortedSupplierEntries[index];
                                final isLowest = index == 0;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(entry.key,
                                      style: AppTextStyles.titleSmall),
                                  subtitle: isLowest
                                      ? Text('Minimum Purchase Cost',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold,
                                          ))
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        PkrFormatter.format(entry.value),
                                        style: AppTextStyles.titleMedium.copyWith(
                                          color: isLowest
                                              ? AppColors.success
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            size: 18, color: AppColors.error),
                                        onPressed: () {
                                          setState(() {
                                            _supplierCosts.remove(entry.key);
                                          });
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

                  // Section 4: Customer-Specific Wholesale Prices
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('4. Customer Wholesale Prices',
                                  style: AppTextStyles.titleMedium),
                              TextButton.icon(
                                onPressed: _showAddCustomerPriceDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Custom Price'),
                              ),
                            ],
                          ),
                          Text(
                            'Custom wholesale prices for specific B2B client accounts:',
                            style: AppTextStyles.bodySmall,
                          ),
                          const Divider(height: 16),

                          if (_customerPrices.isEmpty) ...[
                            Text('No customer custom prices configured.',
                                style: AppTextStyles.bodySmall),
                          ] else ...[
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _customerPrices.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 8),
                              itemBuilder: (context, index) {
                                final custId =
                                    _customerPrices.keys.elementAt(index);
                                final pricePkr = _customerPrices[custId]!;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(custId,
                                      style: AppTextStyles.titleSmall),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        PkrFormatter.format(pricePkr),
                                        style: AppTextStyles.titleMedium.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            size: 18, color: AppColors.error),
                                        onPressed: () {
                                          setState(() {
                                            _customerPrices.remove(custId);
                                          });
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

                  // Section 5: Optional Product Image
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('5. Product Image',
                                  style: AppTextStyles.titleMedium),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Optional',
                                    style: AppTextStyles.labelSmall),
                              ),
                            ],
                          ),
                          const Divider(height: 16),

                          if (_existingImageUrl != null &&
                              _existingImageUrl!.isNotEmpty) ...[
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _existingImageUrl!,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          Text(
                            'Images are optional. Product cards will display an executive placeholder if no image is uploaded.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.textOnPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(isEditing
                            ? 'Update Product Catalog'
                            : 'Save Product to Catalog'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
