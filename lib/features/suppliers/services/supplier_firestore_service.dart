import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier_model.dart';

class SupplierFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _suppliersRef =>
      _firestore.collection('suppliers');

  /// Stream of all suppliers sorted by name
  Stream<List<SupplierModel>> watchSuppliers() {
    return _suppliersRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SupplierModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Add new Supplier
  Future<String> addSupplier(SupplierModel supplier) async {
    final docRef = await _suppliersRef.add(supplier.toMap());
    return docRef.id;
  }

  /// Update existing Supplier
  Future<void> updateSupplier(SupplierModel supplier) async {
    await _suppliersRef.doc(supplier.id).update(supplier.toMap());
  }

  /// Delete Supplier
  Future<void> deleteSupplier(String id) async {
    await _suppliersRef.doc(id).delete();
  }
}
