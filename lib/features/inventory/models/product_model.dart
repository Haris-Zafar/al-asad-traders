import 'package:cloud_firestore/cloud_firestore.dart';

/// Product Model for Inventory items
class ProductModel {
  final String id;
  final String name;
  final String barcode;
  final int defaultWholesalePricePkr; // Strict integer PKR
  final int retailPricePkr; // Strict integer PKR
  final int currentStock;
  final bool isArchived;
  final String? imageUrl;
  final Map<String, int> supplierCosts; // supplierId -> costPkr
  final Map<String, int> customerPrices; // customerId -> customPkr
  final DateTime? createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.defaultWholesalePricePkr,
    required this.retailPricePkr,
    required this.currentStock,
    this.isArchived = false,
    this.imageUrl,
    this.supplierCosts = const {},
    this.customerPrices = const {},
    this.createdAt,
  });

  /// Check if stock is low (below threshold, e.g. 10 units)
  bool get isLowStock => currentStock <= 10;

  /// Returns effective wholesale price for a specific customer ID, or default wholesale price
  int getWholesalePriceForCustomer(String? customerId) {
    if (customerId != null && customerPrices.containsKey(customerId)) {
      return customerPrices[customerId]!;
    }
    return defaultWholesalePricePkr;
  }

  /// Returns lowest purchase cost among recorded suppliers, or null if none
  int? get lowestSupplierCostPkr {
    if (supplierCosts.isEmpty) return null;
    int? lowest;
    for (final cost in supplierCosts.values) {
      if (lowest == null || cost < lowest) {
        lowest = cost;
      }
    }
    return lowest;
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Parse supplier costs map safely ensuring integer PKR values
    final rawSupplierCosts = map['supplierCosts'] as Map<String, dynamic>? ?? {};
    final supplierCostsMap = <String, int>{};
    rawSupplierCosts.forEach((key, value) {
      supplierCostsMap[key] = (value as num).toInt();
    });

    // Parse customer prices map safely ensuring integer PKR values
    final rawCustomerPrices = map['customerPrices'] as Map<String, dynamic>? ?? {};
    final customerPricesMap = <String, int>{};
    rawCustomerPrices.forEach((key, value) {
      customerPricesMap[key] = (value as num).toInt();
    });

    return ProductModel(
      id: documentId,
      name: map['name'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      defaultWholesalePricePkr:
          (map['defaultWholesalePricePkr'] as num?)?.toInt() ?? 0,
      retailPricePkr: (map['retailPricePkr'] as num?)?.toInt() ?? 0,
      currentStock: (map['currentStock'] as num?)?.toInt() ?? 0,
      isArchived: map['isArchived'] as bool? ?? false,
      imageUrl: map['imageUrl'] as String?,
      supplierCosts: supplierCostsMap,
      customerPrices: customerPricesMap,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'barcode': barcode,
      'defaultWholesalePricePkr': defaultWholesalePricePkr,
      'retailPricePkr': retailPricePkr,
      'currentStock': currentStock,
      'isArchived': isArchived,
      'imageUrl': imageUrl,
      'supplierCosts': supplierCosts,
      'customerPrices': customerPrices,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? barcode,
    int? defaultWholesalePricePkr,
    int? retailPricePkr,
    int? currentStock,
    bool? isArchived,
    String? imageUrl,
    Map<String, int>? supplierCosts,
    Map<String, int>? customerPrices,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      defaultWholesalePricePkr:
          defaultWholesalePricePkr ?? this.defaultWholesalePricePkr,
      retailPricePkr: retailPricePkr ?? this.retailPricePkr,
      currentStock: currentStock ?? this.currentStock,
      isArchived: isArchived ?? this.isArchived,
      imageUrl: imageUrl ?? this.imageUrl,
      supplierCosts: supplierCosts ?? this.supplierCosts,
      customerPrices: customerPrices ?? this.customerPrices,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
