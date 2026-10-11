import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/pkr_formatter.dart';
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
  final _retailPriceController = TextEditingController();
  final _stockController = TextEditingController();

  String? _existingImageUrl;
  bool _isInitialLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _populateExistingData(ProductModel product) {
    if (!_isInitialLoaded) {
      _nameController.text = product.name;
      _barcodeController.text = product.barcode;
      _wholesalePriceController.text =
          product.defaultWholesalePricePkr.toString();
      _retailPriceController.text = product.retailPricePkr.toString();
      _stockController.text = product.currentStock.toString();
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Scanned Barcode: $scannedCode'),
                            backgroundColor: AppColors.success,
                          ),
                        );
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

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final wholesalePkr =
          PkrFormatter.parsePkr(_wholesalePriceController.text) ?? 0;
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
            retailPricePkr: retailPkr,
            currentStock: stock,
            existingImageUrl: _existingImageUrl,
          );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.productId == null
                ? 'Product added to inventory'
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
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

                  // Product Name Input
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      hintText: 'e.g. Basmati Rice 5kg',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter product name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Barcode Input + Scanner Trigger
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

                  // Wholesale Price PKR Input (Strict Integer Standard)
                  TextFormField(
                    controller: _wholesalePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Default Wholesale Price (PKR)',
                      hintText: '1200',
                      prefixText: 'Rs. ',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter default wholesale price';
                      }
                      final pkr = PkrFormatter.parsePkr(val);
                      if (pkr == null || pkr < 0) {
                        return 'Please enter a valid integer PKR amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Retail Price PKR Input (Strict Integer Standard)
                  TextFormField(
                    controller: _retailPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Retail Price (PKR)',
                      hintText: '1400',
                      prefixText: 'Rs. ',
                      prefixIcon: Icon(Icons.price_change_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter retail price';
                      }
                      final pkr = PkrFormatter.parsePkr(val);
                      if (pkr == null || pkr < 0) {
                        return 'Please enter a valid integer PKR amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Initial Stock Quantity Input
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current Available Stock (Units)',
                      hintText: '150',
                      prefixIcon: Icon(Icons.format_list_numbered_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter stock quantity';
                      }
                      final stock = int.tryParse(val.trim());
                      if (stock == null || stock < 0) {
                        return 'Please enter valid stock units';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save Product Button
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _handleSubmit,
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.textOnPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(isEditing ? 'Update Product' : 'Save Product'),
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
