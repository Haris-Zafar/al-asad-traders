import 'package:cloud_firestore/cloud_firestore.dart';

import '../../invoices/models/invoice_item_snapshot.dart';
import '../../invoices/models/invoice_model.dart';
import '../models/customer_order_model.dart';

class B2bPortalFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _invoicesRef =>
      _firestore.collection('invoices');

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  /// Stream of orders for a specific customer
  Stream<List<CustomerOrderModel>> watchCustomerOrders(String customerId) {
    return _ordersRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomerOrderModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream of all incoming B2B orders (for Wholesaler Fulfillment)
  Stream<List<CustomerOrderModel>> watchAllOrders() {
    return _ordersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomerOrderModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Place new B2B Order Request
  Future<String> placeOrder(CustomerOrderModel order) async {
    final docRef = await _ordersRef.add(order.toMap());
    return docRef.id;
  }

  /// Fulfill order and convert directly into an official PKR Invoice
  Future<String> fulfillAndConvertToInvoice({
    required CustomerOrderModel order,
    required List<OrderItemSnapshot> deliveredItems,
    required String adjustmentNote,
  }) async {
    final batch = _firestore.batch();
    final newInvoiceRef = _invoicesRef.doc();

    final actualTotalPkr = deliveredItems.fold<int>(
      0,
      (acc, item) => acc + (item.estimatedPricePkr * item.quantity),
    );

    // 1. Create Invoice Document
    final invoiceItems = deliveredItems.map((item) {
      return InvoiceItemSnapshot(
        productId: item.productId,
        productName: item.productName,
        unitPricePkr: item.estimatedPricePkr,
        purchaseCostPkr: 0,
        quantity: item.quantity,
        subtotalPkr: item.subtotalPkr,
      );
    }).toList();

    final invoice = InvoiceModel(
      id: '',
      customerId: order.customerId,
      customerName: order.customerName,
      createdAt: DateTime.now(),
      items: invoiceItems,
      grandTotalPkr: actualTotalPkr,
    );

    batch.set(newInvoiceRef, invoice.toMap());

    // 2. Update Order Status to Delivered
    final orderRef = _ordersRef.doc(order.id);
    batch.update(orderRef, {
      'status': OrderStatus.delivered.toFormattedString(),
      'actualDeliveredTotalPkr': actualTotalPkr,
      'adjustmentNote': adjustmentNote,
    });

    // 3. Deduct stock from Inventory
    for (final item in deliveredItems) {
      final productRef = _productsRef.doc(item.productId);
      batch.update(productRef, {
        'currentStock': FieldValue.increment(-item.quantity),
      });
    }

    await batch.commit();
    return newInvoiceRef.id;
  }
}
