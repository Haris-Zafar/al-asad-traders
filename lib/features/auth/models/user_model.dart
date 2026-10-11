import 'package:cloud_firestore/cloud_firestore.dart';

/// User Role Enum
enum UserRole {
  wholesaler,
  customer;

  static UserRole userRoleFromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'wholesaler':
      case 'admin':
        return UserRole.wholesaler;
      case 'customer':
      case 'client':
      default:
        return UserRole.customer;
    }
  }

  String toFormattedString() {
    switch (this) {
      case UserRole.wholesaler:
        return 'wholesaler';
      case UserRole.customer:
        return 'customer';
    }
  }
}

/// User Model representing wholesalers and B2B customer accounts
class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phoneNumber;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.createdAt,
  });

  bool get isWholesaler => role == UserRole.wholesaler;
  bool get isCustomer => role == UserRole.customer;

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: UserRole.userRoleFromString(map['role'] as String?),
      phoneNumber: map['phoneNumber'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toFormattedString(),
      'phoneNumber': phoneNumber,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? phoneNumber,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
