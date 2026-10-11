import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_model.dart';
import '../services/customer_firestore_service.dart';

final customerFirestoreServiceProvider =
    Provider<CustomerFirestoreService>((ref) {
  return CustomerFirestoreService();
});

/// Stream Provider of all B2B Customers
final customersStreamProvider = StreamProvider<List<CustomerModel>>((ref) {
  final service = ref.watch(customerFirestoreServiceProvider);
  return service.watchCustomers();
});

class CustomerController extends StateNotifier<AsyncValue<void>> {
  final CustomerFirestoreService _service;

  CustomerController(this._service) : super(const AsyncValue.data(null));

  Future<bool> saveCustomer({
    String? existingId,
    required String name,
    required String phone,
    required String email,
    required String address,
    int initialBalancePkr = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final customer = CustomerModel(
        id: existingId ?? '',
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        address: address.trim(),
        outstandingBalancePkr: initialBalancePkr,
        createdAt: DateTime.now(),
      );

      if (existingId != null && existingId.isNotEmpty) {
        await _service.updateCustomer(customer);
      } else {
        await _service.addCustomer(customer);
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _service.deleteCustomer(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final customerControllerProvider =
    StateNotifierProvider<CustomerController, AsyncValue<void>>((ref) {
  final service = ref.watch(customerFirestoreServiceProvider);
  return CustomerController(service);
});
