import 'package:cloud_firestore/cloud_firestore.dart';
import 'invoice_item_snapshot.dart';

/// Invoice Document Model
class InvoiceModel {
  final String id;
  final String customerId;
  final String customerName;
  final DateTime createdAt;
  final List<InvoiceItemSnapshot> items;
  final int grandTotalPkr; // Strict integer PKR
  final String? pdfCloudinaryUrl;

  const InvoiceModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.createdAt,
    required this.items,
    required this.grandTotalPkr,
    this.pdfCloudinaryUrl,
  });

  /// Calculates total purchase cost for profit margin analytics
  int get totalPurchaseCostPkr {
    return items.fold<int>(
      0,
      (total, item) => total + (item.purchaseCostPkr * item.quantity),
    );
  }

  /// Calculates net profit PKR on this invoice
  int get estimatedNetProfitPkr => grandTotalPkr - totalPurchaseCostPkr;

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((i) => InvoiceItemSnapshot.fromMap(i as Map<String, dynamic>))
        .toList();

    return InvoiceModel(
      id: documentId,
      customerId: map['customerId'] as String? ?? 'walk_in',
      customerName: map['customerName'] as String? ?? 'Walk-in Customer',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      items: itemsList,
      grandTotalPkr: (map['grandTotalPkr'] as num?)?.toInt() ?? 0,
      pdfCloudinaryUrl: map['pdfCloudinaryUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'items': items.map((i) => i.toMap()).toList(),
      'grandTotalPkr': grandTotalPkr,
      'pdfCloudinaryUrl': pdfCloudinaryUrl,
    };
  }
}
