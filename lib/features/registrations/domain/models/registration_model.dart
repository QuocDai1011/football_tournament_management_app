import 'package:cloud_firestore/cloud_firestore.dart';

enum RegistrationStatus { pending, approved, rejected }

extension RegistrationStatusExtension on RegistrationStatus {
  String get displayName {
    switch (this) {
      case RegistrationStatus.pending:
        return 'Pending';
      case RegistrationStatus.approved:
        return 'Approved';
      case RegistrationStatus.rejected:
        return 'Rejected';
    }
  }

  String get value {
    switch (this) {
      case RegistrationStatus.pending:
        return 'pending';
      case RegistrationStatus.approved:
        return 'approved';
      case RegistrationStatus.rejected:
        return 'rejected';
    }
  }

  static RegistrationStatus fromString(String value) {
    switch (value) {
      case 'approved':
        return RegistrationStatus.approved;
      case 'rejected':
        return RegistrationStatus.rejected;
      default:
        return RegistrationStatus.pending;
    }
  }
}

class RegistrationModel {
  final String id;
  final String tournamentId;
  final String? seasonId;
  final String teamId;
  final String teamName; // Denormalized
  final String? teamLogoUrl; // Denormalized
  final String? group;
  final RegistrationStatus status;
  final DateTime registeredAt;
  final DateTime? approvedAt;
  final String? notes;

  const RegistrationModel({
    required this.id,
    required this.tournamentId,
    this.seasonId,
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    this.group,
    required this.status,
    required this.registeredAt,
    this.approvedAt,
    this.notes,
  });

  factory RegistrationModel.fromJson(Map<String, dynamic> json, String id) {
    return RegistrationModel(
      id: id,
      tournamentId: json['tournamentId'] as String,
      seasonId: json['seasonId'] as String?,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String? ?? '',
      teamLogoUrl: json['teamLogoUrl'] as String?,
      group: json['group'] as String?,
      status: RegistrationStatusExtension.fromString(
          json['status'] as String? ?? ''),
      registeredAt:
          (json['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (json['approvedAt'] as Timestamp?)?.toDate(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'tournamentId': tournamentId,
        'seasonId': seasonId,
        'teamId': teamId,
        'teamName': teamName,
        'teamLogoUrl': teamLogoUrl,
        'group': group,
        'status': status.value,
        'registeredAt': Timestamp.fromDate(registeredAt),
        'approvedAt':
            approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
        'notes': notes,
      };

  RegistrationModel copyWith({
    String? group,
    RegistrationStatus? status,
    DateTime? approvedAt,
    String? notes,
  }) {
    return RegistrationModel(
      id: id,
      tournamentId: tournamentId,
      seasonId: seasonId,
      teamId: teamId,
      teamName: teamName,
      teamLogoUrl: teamLogoUrl,
      group: group ?? this.group,
      status: status ?? this.status,
      registeredAt: registeredAt,
      approvedAt: approvedAt ?? this.approvedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegistrationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
