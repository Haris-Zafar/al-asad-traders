import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/cloudinary_service.dart';
import '../models/product_model.dart';
import '../services/inventory_firestore_service.dart';

final inventoryFirestoreServiceProvider = Provider<InventoryFirestoreService>((ref) {
  return InventoryFirestoreService();
});

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

/// Search Query State
final inventorySearchQueryProvider = StateProvider<String>((ref) => '');

/// Include Archived Toggle State
final showArchivedProductsProvider = StateProvider<bool>((ref) => false);

/// Filtered Products Stream Provider
final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  final service = ref.watch(inventoryFirestoreServiceProvider);
  final showArchived = ref.watch(showArchivedProductsProvider);
  final searchQuery = ref.watch(inventorySearchQueryProvider).toLowerCase().trim();

  return service.watchProducts(includeArchived: showArchived).map((products) {
    if (searchQuery.isEmpty) return products;
    return products.where((product) {
      final nameMatches = product.name.toLowerCase().contains(searchQuery);
      final barcodeMatches = product.barcode.toLowerCase().contains(searchQuery);
      return nameMatches || barcodeMatches;
    }).toList();
  });
});

/// Single Product Detail Provider
final productDetailProvider =
    FutureProvider.family<ProductModel?, String>((ref, id) async {
  final service = ref.watch(inventoryFirestoreServiceProvider);
  return await service.getProductById(id);
});

/// Inventory Controller State
class InventoryControllerState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const InventoryControllerState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  InventoryControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return InventoryControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class InventoryController extends StateNotifier<InventoryControllerState> {
  final InventoryFirestoreService _service;
  final CloudinaryService _cloudinaryService;

  InventoryController(this._service, this._cloudinaryService)
      : super(const InventoryControllerState());

  Future<bool> saveProduct({
    String? existingId,
    required String name,
    required String barcode,
    required int defaultWholesalePricePkr,
    int defaultCostPricePkr = 0,
    required int retailPricePkr,
    required int currentStock,
    String note = '',
    Map<String, int> supplierCosts = const {},
    Map<String, int> customerPrices = const {},
    String? localImagePath,
    List<int>? imageBytes,
    String? existingImageUrl,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    try {
      String? imageUrl = existingImageUrl;

      // Upload image to Cloudinary if new image selected
      if (localImagePath != null && localImagePath.isNotEmpty) {
        imageUrl = await _cloudinaryService.uploadImage(localImagePath);
      } else if (imageBytes != null && imageBytes.isNotEmpty) {
        imageUrl = await _cloudinaryService.uploadImageBytes(
          imageBytes,
          'prod_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      final product = ProductModel(
        id: existingId ?? '',
        name: name.trim(),
        barcode: barcode.trim(),
        defaultWholesalePricePkr: defaultWholesalePricePkr,
        defaultCostPricePkr: defaultCostPricePkr,
        retailPricePkr: retailPricePkr,
        currentStock: currentStock,
        note: note.trim(),
        supplierCosts: supplierCosts,
        customerPrices: customerPrices,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      if (existingId != null && existingId.isNotEmpty) {
        await _service.updateProduct(product);
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Product updated successfully.',
        );
      } else {
        await _service.addProduct(product);
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Product added successfully.',
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save product: $e',
      );
      return false;
    }
  }

  Future<void> toggleArchiveProduct(String productId, bool currentArchived) async {
    try {
      await _service.toggleArchiveProduct(productId, !currentArchived);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update archive status: $e');
    }
  }

  Future<void> addOrUpdateSupplierCost({
    required String productId,
    required String supplierId,
    required int costPkr,
  }) async {
    try {
      await _service.setSupplierCost(
        productId: productId,
        supplierId: supplierId,
        costPkr: costPkr,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save supplier cost: $e');
    }
  }

  Future<void> removeSupplierCost({
    required String productId,
    required String supplierId,
  }) async {
    try {
      await _service.removeSupplierCost(
        productId: productId,
        supplierId: supplierId,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove supplier cost: $e');
    }
  }

  Future<void> setCustomerPrice({
    required String productId,
    required String customerId,
    required int pricePkr,
  }) async {
    try {
      await _service.setCustomerPrice(
        productId: productId,
        customerId: customerId,
        pricePkr: pricePkr,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save customer price: $e');
    }
  }
}

final inventoryControllerProvider =
    StateNotifierProvider<InventoryController, InventoryControllerState>((ref) {
  final service = ref.watch(inventoryFirestoreServiceProvider);
  final cloudinary = ref.watch(cloudinaryServiceProvider);
  return InventoryController(service, cloudinary);
});
