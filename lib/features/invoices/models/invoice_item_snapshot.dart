import '../../inventory/models/product_model.dart';

/// Price Snapshot Item for Invoice payloads
/// Strictly retains unit price and cost at the exact time of invoice creation.
class InvoiceItemSnapshot {
  final String productId;
  final String productName;
  final int unitPricePkr; // Strict integer PKR
  final int purchaseCostPkr; // Strict integer PKR
  final int quantity;
  final int subtotalPkr; // unitPricePkr * quantity

  const InvoiceItemSnapshot({
    required this.productId,
    required this.productName,
    required this.unitPricePkr,
    required this.purchaseCostPkr,
    required this.quantity,
    required this.subtotalPkr,
  });

  /// Creates a price snapshot from a ProductModel for a specific customer
  factory InvoiceItemSnapshot.fromProduct({
    required ProductModel product,
    required int quantity,
    String? customerId,
  }) {
    final unitPrice = product.getWholesalePriceForCustomer(customerId);
    final purchaseCost = product.lowestSupplierCostPkr ?? 0;
    return InvoiceItemSnapshot(
      productId: product.id,
      productName: product.name,
      unitPricePkr: unitPrice,
      purchaseCostPkr: purchaseCost,
      quantity: quantity,
      subtotalPkr: unitPrice * quantity,
    );
  }

  InvoiceItemSnapshot copyWith({
    String? productId,
    String? productName,
    int? unitPricePkr,
    int? purchaseCostPkr,
    int? quantity,
  }) {
    final newQty = quantity ?? this.quantity;
    final newPrice = unitPricePkr ?? this.unitPricePkr;
    return InvoiceItemSnapshot(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPricePkr: newPrice,
      purchaseCostPkr: purchaseCostPkr ?? this.purchaseCostPkr,
      quantity: newQty,
      subtotalPkr: newPrice * newQty,
    );
  }

  factory InvoiceItemSnapshot.fromMap(Map<String, dynamic> map) {
    final price = (map['unitPricePkr'] as num?)?.toInt() ?? 0;
    final qty = (map['quantity'] as num?)?.toInt() ?? 0;
    return InvoiceItemSnapshot(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      unitPricePkr: price,
      purchaseCostPkr: (map['purchaseCostPkr'] as num?)?.toInt() ?? 0,
      quantity: qty,
      subtotalPkr: (map['subtotalPkr'] as num?)?.toInt() ?? (price * qty),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPricePkr': unitPricePkr,
      'purchaseCostPkr': purchaseCostPkr,
      'quantity': quantity,
      'subtotalPkr': subtotalPkr,
    };
  }
}
