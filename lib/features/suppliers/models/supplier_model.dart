import 'package:cloud_firestore/cloud_firestore.dart';

/// Supplier Model representing seller contacts and distributors
class SupplierModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String catalogNotes;
  final DateTime? createdAt;

  const SupplierModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.catalogNotes = '',
    this.createdAt,
  });

  factory SupplierModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SupplierModel(
      id: documentId,
      name: map['name'] as String? ?? 'Unknown Supplier',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      catalogNotes: map['catalogNotes'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'catalogNotes': catalogNotes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  SupplierModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? catalogNotes,
    DateTime? createdAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      catalogNotes: catalogNotes ?? this.catalogNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
