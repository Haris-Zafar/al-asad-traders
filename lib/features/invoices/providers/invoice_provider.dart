import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/models/product_model.dart';
import '../models/invoice_item_snapshot.dart';
import '../models/invoice_model.dart';
import '../services/invoice_firestore_service.dart';

final invoiceFirestoreServiceProvider = Provider<InvoiceFirestoreService>((ref) {
  return InvoiceFirestoreService();
});

/// Stream Provider of all Invoices
final invoicesStreamProvider = StreamProvider<List<InvoiceModel>>((ref) {
  final service = ref.watch(invoiceFirestoreServiceProvider);
  return service.watchInvoices();
});

/// Single Invoice Detail Provider
final invoiceDetailProvider =
    FutureProvider.family<InvoiceModel?, String>((ref, id) async {
  final service = ref.watch(invoiceFirestoreServiceProvider);
  return await service.getInvoiceById(id);
});

/// Invoice Cart & Creator State
class InvoiceCartState {
  final String customerId;
  final String customerName;
  final List<InvoiceItemSnapshot> items;
  final bool isLoading;
  final String? errorMessage;
  final String? createdInvoiceId;

  const InvoiceCartState({
    this.customerId = 'walk_in',
    this.customerName = 'Walk-in Customer',
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.createdInvoiceId,
  });

  int get grandTotalPkr {
    return items.fold<int>(0, (sum, item) => sum + item.subtotalPkr);
  }

  InvoiceCartState copyWith({
    String? customerId,
    String? customerName,
    List<InvoiceItemSnapshot>? items,
    bool? isLoading,
    String? errorMessage,
    String? createdInvoiceId,
  }) {
    return InvoiceCartState(
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      createdInvoiceId: createdInvoiceId,
    );
  }
}

class InvoiceBuilderNotifier extends StateNotifier<InvoiceCartState> {
  final InvoiceFirestoreService _service;

  InvoiceBuilderNotifier(this._service) : super(const InvoiceCartState());

  void setCustomer({required String id, required String name}) {
    state = state.copyWith(
      customerId: id,
      customerName: name,
    );

    // Re-evaluate unit prices for existing items based on customer-specific prices
    // (Note: snapshots remain locked upon adding, but customer change refreshes current cart preview)
  }

  void addProductToCart(ProductModel product, {int quantity = 1}) {
    final existingIndex =
        state.items.indexWhere((item) => item.productId == product.id);

    if (existingIndex != -1) {
      final existingItem = state.items[existingIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      final updatedItems = List<InvoiceItemSnapshot>.from(state.items);
      updatedItems[existingIndex] = updatedItem;
      state = state.copyWith(items: updatedItems);
    } else {
      final newItem = InvoiceItemSnapshot.fromProduct(
        product: product,
        quantity: quantity,
        customerId: state.customerId,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String productId) {
    final updatedItems =
        state.items.where((item) => item.productId != productId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void clearCart() {
    state = const InvoiceCartState();
  }

  Future<String?> submitInvoice() async {
    if (state.items.isEmpty) {
      state = state.copyWith(errorMessage: 'Cannot create empty invoice.');
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final invoice = InvoiceModel(
        id: '',
        customerId: state.customerId,
        customerName: state.customerName,
        createdAt: DateTime.now(),
        items: state.items,
        grandTotalPkr: state.grandTotalPkr,
      );

      final newInvoiceId = await _service.createInvoice(invoice);
      state = state.copyWith(
        isLoading: false,
        createdInvoiceId: newInvoiceId,
      );
      return newInvoiceId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create invoice: $e',
      );
      return null;
    }
  }
}

final invoiceBuilderProvider =
    StateNotifierProvider<InvoiceBuilderNotifier, InvoiceCartState>((ref) {
  final service = ref.watch(invoiceFirestoreServiceProvider);
  return InvoiceBuilderNotifier(service);
});
