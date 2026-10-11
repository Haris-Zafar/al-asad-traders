import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../models/supplier_model.dart';
import '../providers/supplier_provider.dart';

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  void _showSupplierDialog(BuildContext context, WidgetRef ref, [SupplierModel? existing]) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final addressController = TextEditingController(text: existing?.address ?? '');
    final notesController = TextEditingController(text: existing?.catalogNotes ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Supplier' : 'Edit Supplier'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Name',
                      hintText: 'e.g. National Grain Mills',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      hintText: '0300 1234567',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address / Location (Optional)',
                      hintText: 'Grain Market, Faisalabad',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catalog Notes / Products Supplied',
                      hintText: 'Supplies premium basmati rice & pulses',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext);
                  await ref.read(supplierControllerProvider.notifier).saveSupplier(
                        existingId: existing?.id,
                        name: nameController.text,
                        phone: phoneController.text,
                        address: addressController.text,
                        notes: notesController.text,
                      );
                }
              },
              child: const Text('Save Supplier'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            tooltip: 'View Auto Purchase List',
            onPressed: () {
              context.push(RoutePaths.purchaseList);
            },
          ),
        ],
      ),
      body: suppliersAsync.when(
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
        error: (err, _) => Center(child: Text('Error loading suppliers: $err')),
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text('No Suppliers Found', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Add suppliers to track cost options for inventory products.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showSupplierDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Supplier'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: suppliers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final supplier = suppliers[index];

              return Card(
                child: ListTile(
                  title: Text(supplier.name, style: AppTextStyles.titleSmall),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (supplier.phone.isNotEmpty)
                        Text('Phone: ${supplier.phone}',
                            style: AppTextStyles.bodySmall),
                      if (supplier.address.isNotEmpty)
                        Text('Location: ${supplier.address}',
                            style: AppTextStyles.bodySmall),
                      if (supplier.catalogNotes.isNotEmpty)
                        Text('Notes: ${supplier.catalogNotes}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            )),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showSupplierDialog(context, ref, supplier),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: AppColors.error),
                        onPressed: () {
                          ref
                              .read(supplierControllerProvider.notifier)
                              .deleteSupplier(supplier.id);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSupplierDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
    );
  }
}
