import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  adjusted,
  delivered,
  cancelled;

  static OrderStatus fromStatusString(String? status) {
    switch (status?.toLowerCase()) {
      case 'adjusted':
        return OrderStatus.adjusted;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  String toFormattedString() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.adjusted:
        return 'adjusted';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

class OrderItemSnapshot {
  final String productId;
  final String productName;
  final int quantity;
  final int estimatedPricePkr; // Strict integer PKR
  final int subtotalPkr; // quantity * estimatedPricePkr

  const OrderItemSnapshot({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.estimatedPricePkr,
    required this.subtotalPkr,
  });

  OrderItemSnapshot copyWith({
    String? productId,
    String? productName,
    int? quantity,
    int? estimatedPricePkr,
  }) {
    final qty = quantity ?? this.quantity;
    final price = estimatedPricePkr ?? this.estimatedPricePkr;
    return OrderItemSnapshot(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: qty,
      estimatedPricePkr: price,
      subtotalPkr: qty * price,
    );
  }

  factory OrderItemSnapshot.fromMap(Map<String, dynamic> map) {
    final qty = (map['quantity'] as num?)?.toInt() ?? 0;
    final price = (map['estimatedPricePkr'] as num?)?.toInt() ?? 0;
    return OrderItemSnapshot(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      quantity: qty,
      estimatedPricePkr: price,
      subtotalPkr: (map['subtotalPkr'] as num?)?.toInt() ?? (qty * price),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'estimatedPricePkr': estimatedPricePkr,
      'subtotalPkr': subtotalPkr,
    };
  }
}

class CustomerOrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final OrderStatus status;
  final List<OrderItemSnapshot> requestedItems;
  final int estimatedTotalPkr; // Strict integer PKR
  final int actualDeliveredTotalPkr; // Strict integer PKR
  final String adjustmentNote;
  final DateTime createdAt;

  const CustomerOrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.requestedItems,
    required this.estimatedTotalPkr,
    required this.actualDeliveredTotalPkr,
    this.adjustmentNote = '',
    required this.createdAt,
  });

  factory CustomerOrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawItems = map['requestedItems'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((i) => OrderItemSnapshot.fromMap(i as Map<String, dynamic>))
        .toList();

    return CustomerOrderModel(
      id: documentId,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? 'B2B Client',
      status: OrderStatus.fromStatusString(map['status'] as String?),
      requestedItems: items,
      estimatedTotalPkr: (map['estimatedTotalPkr'] as num?)?.toInt() ?? 0,
      actualDeliveredTotalPkr:
          (map['actualDeliveredTotalPkr'] as num?)?.toInt() ?? 0,
      adjustmentNote: map['adjustmentNote'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'status': status.toFormattedString(),
      'requestedItems': requestedItems.map((i) => i.toMap()).toList(),
      'estimatedTotalPkr': estimatedTotalPkr,
      'actualDeliveredTotalPkr': actualDeliveredTotalPkr,
      'adjustmentNote': adjustmentNote,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
