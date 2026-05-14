import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/date_utils.dart';

/// Admin model representing the authenticated admin user
class AdminModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const AdminModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json, String id) {
    return AdminModel(
      id: id,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? 'Admin',
      photoUrl: json['photoUrl'] as String?,
      // Dùng AppDateUtils để xử lý Timestamp, String, int
      createdAt: AppDateUtils.parseDateOrNow(json['createdAt']),
      lastLoginAt: AppDateUtils.parseDateOrNow(json['lastLoginAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      };

  AdminModel copyWith({
    String? displayName,
    String? photoUrl,
    DateTime? lastLoginAt,
  }) {
    return AdminModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
