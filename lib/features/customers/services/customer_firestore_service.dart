import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customersRef =>
      _firestore.collection('customers');

  /// Stream of all registered B2B Customers sorted by name
  Stream<List<CustomerModel>> watchCustomers() {
    return _customersRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomerModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get single customer by ID
  Future<CustomerModel?> getCustomerById(String id) async {
    final doc = await _customersRef.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return CustomerModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Add new Customer
  Future<String> addCustomer(CustomerModel customer) async {
    final docRef = await _customersRef.add(customer.toMap());
    return docRef.id;
  }

  /// Update Customer details
  Future<void> updateCustomer(CustomerModel customer) async {
    await _customersRef.doc(customer.id).update(customer.toMap());
  }

  /// Delete Customer
  Future<void> deleteCustomer(String id) async {
    await _customersRef.doc(id).delete();
  }

  /// Update customer's outstanding balance
  Future<void> updateOutstandingBalance(String customerId, int deltaPkr) async {
    await _customersRef.doc(customerId).update({
      'outstandingBalancePkr': FieldValue.increment(deltaPkr),
    });
  }
}
