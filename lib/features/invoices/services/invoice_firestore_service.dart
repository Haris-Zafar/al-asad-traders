import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';

class InvoiceFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _invoicesRef =>
      _firestore.collection('invoices');

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  /// Stream of all invoices sorted by creation date
  Stream<List<InvoiceModel>> watchInvoices() {
    return _invoicesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get single invoice by ID
  Future<InvoiceModel?> getInvoiceById(String id) async {
    final doc = await _invoicesRef.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return InvoiceModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Create new Invoice document and deduct product inventory stock automatically
  Future<String> createInvoice(InvoiceModel invoice) async {
    final batch = _firestore.batch();
    final newInvoiceRef = _invoicesRef.doc();

    // 1. Set Invoice document
    batch.set(newInvoiceRef, invoice.toMap());

    // 2. Decrement stock for each item in the invoice
    for (final item in invoice.items) {
      final productDocRef = _productsRef.doc(item.productId);
      batch.update(productDocRef, {
        'currentStock': FieldValue.increment(-item.quantity),
      });
    }

    // Commit atomic batch write
    await batch.commit();
    return newInvoiceRef.id;
  }
}
