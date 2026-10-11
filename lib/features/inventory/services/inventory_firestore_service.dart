import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class InventoryFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  /// Stream of all products with optional archive filter
  Stream<List<ProductModel>> watchProducts({bool includeArchived = false}) {
    Query<Map<String, dynamic>> query = _productsRef;
    if (!includeArchived) {
      query = query.where('isArchived', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get product by ID
  Future<ProductModel?> getProductById(String id) async {
    final doc = await _productsRef.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return ProductModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Lookup product by Barcode
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final query = await _productsRef
        .where('barcode', isEqualTo: barcode.trim())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return ProductModel.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }

  /// Add new product
  Future<String> addProduct(ProductModel product) async {
    final docRef = await _productsRef.add(product.toMap());
    return docRef.id;
  }

  /// Update existing product
  Future<void> updateProduct(ProductModel product) async {
    await _productsRef.doc(product.id).update(product.toMap());
  }

  /// Toggle archiving status
  Future<void> toggleArchiveProduct(String productId, bool isArchived) async {
    await _productsRef.doc(productId).update({
      'isArchived': isArchived,
    });
  }

  /// Update supplier cost PKR for a product
  Future<void> setSupplierCost({
    required String productId,
    required String supplierId,
    required int costPkr,
  }) async {
    await _productsRef.doc(productId).update({
      'supplierCosts.$supplierId': costPkr,
    });
  }

  /// Remove supplier cost from product
  Future<void> removeSupplierCost({
    required String productId,
    required String supplierId,
  }) async {
    await _productsRef.doc(productId).update({
      'supplierCosts.$supplierId': FieldValue.delete(),
    });
  }

  /// Set custom customer price PKR for a product
  Future<void> setCustomerPrice({
    required String productId,
    required String customerId,
    required int pricePkr,
  }) async {
    await _productsRef.doc(productId).update({
      'customerPrices.$customerId': pricePkr,
    });
  }
}
