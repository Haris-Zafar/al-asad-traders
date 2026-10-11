import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a specific supplier's purchase cost for a product
class SupplierCostModel {
  final String supplierId;
  final String supplierName;
  final int costPkr; // Strict integer PKR
  final DateTime? lastUpdated;

  const SupplierCostModel({
    required this.supplierId,
    required this.supplierName,
    required this.costPkr,
    this.lastUpdated,
  });

  factory SupplierCostModel.fromMap(Map<String, dynamic> map, String supplierId) {
    return SupplierCostModel(
      supplierId: supplierId,
      supplierName: map['supplierName'] as String? ?? 'Unknown Supplier',
      costPkr: (map['costPkr'] as num?)?.toInt() ?? 0,
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supplierName': supplierName,
      'costPkr': costPkr,
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : FieldValue.serverTimestamp(),
    };
  }
}
