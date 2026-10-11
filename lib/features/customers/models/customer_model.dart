import 'package:cloud_firestore/cloud_firestore.dart';

/// Customer Model representing B2B Clients & Retail Outlets in Wholesaler Portal
class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final int outstandingBalancePkr; // Strict integer PKR balance
  final DateTime? createdAt;

  const CustomerModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.outstandingBalancePkr = 0,
    this.createdAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CustomerModel(
      id: documentId,
      name: map['name'] as String? ?? 'Walk-in Customer',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      outstandingBalancePkr:
          (map['outstandingBalancePkr'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'outstandingBalancePkr': outstandingBalancePkr,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    int? outstandingBalancePkr,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      outstandingBalancePkr:
          outstandingBalancePkr ?? this.outstandingBalancePkr,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
