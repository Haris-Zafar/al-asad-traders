import '../../inventory/models/product_model.dart';

/// Purchase Requirement for automated low-stock replenishment calculations
class PurchaseRequirement {
  final ProductModel product;
  final int requiredStock; // Deficit quantity to reach target stock
  final String? cheapestSupplierName;
  final int? cheapestCostPkr; // Integer PKR standard
  final int totalEstimatedCostPkr; // cheapestCostPkr * requiredStock

  const PurchaseRequirement({
    required this.product,
    required this.requiredStock,
    this.cheapestSupplierName,
    this.cheapestCostPkr,
    required this.totalEstimatedCostPkr,
  });

  factory PurchaseRequirement.fromProduct(ProductModel product, {int targetStock = 50}) {
    final deficit = targetStock > product.currentStock
        ? (targetStock - product.currentStock)
        : 0;

    String? bestSupplier;
    int? lowestCost;

    if (product.supplierCosts.isNotEmpty) {
      product.supplierCosts.forEach((supplier, cost) {
        if (lowestCost == null || cost < lowestCost!) {
          lowestCost = cost;
          bestSupplier = supplier;
        }
      });
    }

    final totalEst = (lowestCost ?? product.defaultWholesalePricePkr) * deficit;

    return PurchaseRequirement(
      product: product,
      requiredStock: deficit,
      cheapestSupplierName: bestSupplier,
      cheapestCostPkr: lowestCost,
      totalEstimatedCostPkr: totalEst,
    );
  }
}
