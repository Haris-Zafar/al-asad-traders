import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../inventory/models/product_model.dart';
import '../../invoices/models/invoice_item_snapshot.dart';
import '../models/customer_order_model.dart';
import '../services/b2b_portal_firestore_service.dart';

final b2bPortalFirestoreServiceProvider =
    Provider<B2bPortalFirestoreService>((ref) {
  return B2bPortalFirestoreService();
});

/// Stream Provider of logged-in Customer's B2B Orders
final customerOrdersStreamProvider =
    StreamProvider<List<CustomerOrderModel>>((ref) {
  final user = ref.watch(currentUserModelProvider).asData?.value;
  if (user == null) return Stream.value([]);

  final service = ref.watch(b2bPortalFirestoreServiceProvider);
  return service.watchCustomerOrders(user.id);
});

/// Stream Provider of All Orders (Wholesaler View)
final allOrdersStreamProvider =
    StreamProvider<List<CustomerOrderModel>>((ref) {
  final service = ref.watch(b2bPortalFirestoreServiceProvider);
  return service.watchAllOrders();
});

/// Customer Cart State for B2B Order Placement
class CustomerCartState {
  final List<OrderItemSnapshot> items;
  final bool isLoading;
  final String? errorMessage;
  final String? successOrderId;

  const CustomerCartState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successOrderId,
  });

  int get estimatedTotalPkr {
    return items.fold<int>(0, (sum, item) => sum + item.subtotalPkr);
  }

  CustomerCartState copyWith({
    List<OrderItemSnapshot>? items,
    bool? isLoading,
    String? errorMessage,
    String? successOrderId,
  }) {
    return CustomerCartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successOrderId: successOrderId,
    );
  }
}

class CustomerCartNotifier extends StateNotifier<CustomerCartState> {
  CustomerCartNotifier() : super(const CustomerCartState());

  void addItem(ProductModel product, String? customerId, {int quantity = 1}) {
    final pricePkr = product.getWholesalePriceForCustomer(customerId);
    final existingIndex =
        state.items.indexWhere((item) => item.productId == product.id);

    if (existingIndex != -1) {
      final existing = state.items[existingIndex];
      final updated = existing.copyWith(quantity: existing.quantity + quantity);
      final updatedList = List<OrderItemSnapshot>.from(state.items);
      updatedList[existingIndex] = updated;
      state = state.copyWith(items: updatedList);
    } else {
      final newItem = OrderItemSnapshot(
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        estimatedPricePkr: pricePkr,
        subtotalPkr: pricePkr * quantity,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String productId, int newQty) {
    if (newQty <= 0) {
      removeItem(productId);
      return;
    }

    final updated = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: newQty);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated);
  }

  void removeItem(String productId) {
    final updated =
        state.items.where((item) => item.productId != productId).toList();
    state = state.copyWith(items: updated);
  }

  void clearCart() {
    state = const CustomerCartState();
  }
}

final customerCartProvider =
    StateNotifierProvider<CustomerCartNotifier, CustomerCartState>((ref) {
  return CustomerCartNotifier();
});

class B2bPortalController extends StateNotifier<AsyncValue<void>> {
  final B2bPortalFirestoreService _service;

  B2bPortalController(this._service) : super(const AsyncValue.data(null));

  Future<String?> placeOrderRequest({
    required String customerId,
    required String customerName,
    required List<OrderItemSnapshot> items,
  }) async {
    state = const AsyncValue.loading();
    try {
      final estTotal = items.fold<int>(0, (sum, i) => sum + i.subtotalPkr);

      final order = CustomerOrderModel(
        id: '',
        customerId: customerId,
        customerName: customerName,
        status: OrderStatus.pending,
        requestedItems: items,
        estimatedTotalPkr: estTotal,
        actualDeliveredTotalPkr: estTotal,
        createdAt: DateTime.now(),
      );

      final newOrderId = await _service.placeOrder(order);
      state = const AsyncValue.data(null);
      return newOrderId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<String?> convertOrderToInvoice({
    required CustomerOrderModel order,
    required List<InvoiceItemSnapshot> actualItems,
    required String adjustmentNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      final orderSnapshots = actualItems.map((item) {
        return OrderItemSnapshot(
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          estimatedPricePkr: item.unitPricePkr,
          subtotalPkr: item.subtotalPkr,
        );
      }).toList();

      final invoiceId = await _service.fulfillAndConvertToInvoice(
        order: order,
        deliveredItems: orderSnapshots,
        adjustmentNote: adjustmentNote,
      );
      state = const AsyncValue.data(null);
      return invoiceId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final b2bPortalControllerProvider =
    StateNotifierProvider<B2bPortalController, AsyncValue<void>>((ref) {
  final service = ref.watch(b2bPortalFirestoreServiceProvider);
  return B2bPortalController(service);
});
