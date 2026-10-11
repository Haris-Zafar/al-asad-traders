import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/providers/inventory_provider.dart';
import '../models/purchase_requirement.dart';
import '../models/supplier_model.dart';
import '../services/supplier_firestore_service.dart';

final supplierFirestoreServiceProvider = Provider<SupplierFirestoreService>((ref) {
  return SupplierFirestoreService();
});

/// Stream Provider of all Suppliers
final suppliersStreamProvider = StreamProvider<List<SupplierModel>>((ref) {
  final service = ref.watch(supplierFirestoreServiceProvider);
  return service.watchSuppliers();
});

/// Calculated Automated Purchase Requirements Provider
final purchaseRequirementsProvider = Provider<List<PurchaseRequirement>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);

  final products = productsAsync.asData?.value ?? [];
  final lowStockProducts =
      products.where((p) => p.isLowStock && !p.isArchived).toList();

  return lowStockProducts.map((p) {
    return PurchaseRequirement.fromProduct(p, targetStock: 50);
  }).toList();
});

/// Total Estimated Purchase Budget PKR
final totalPurchaseRequirementBudgetPkrProvider = Provider<int>((ref) {
  final requirements = ref.watch(purchaseRequirementsProvider);
  return requirements.fold<int>(
    0,
    (sum, req) => sum + req.totalEstimatedCostPkr,
  );
});

class SupplierController extends StateNotifier<AsyncValue<void>> {
  final SupplierFirestoreService _service;

  SupplierController(this._service) : super(const AsyncValue.data(null));

  Future<bool> saveSupplier({
    String? existingId,
    required String name,
    required String phone,
    required String address,
    required String notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final supplier = SupplierModel(
        id: existingId ?? '',
        name: name.trim(),
        phone: phone.trim(),
        address: address.trim(),
        catalogNotes: notes.trim(),
        createdAt: DateTime.now(),
      );

      if (existingId != null && existingId.isNotEmpty) {
        await _service.updateSupplier(supplier);
      } else {
        await _service.addSupplier(supplier);
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _service.deleteSupplier(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final supplierControllerProvider =
    StateNotifierProvider<SupplierController, AsyncValue<void>>((ref) {
  final service = ref.watch(supplierFirestoreServiceProvider);
  return SupplierController(service);
});
