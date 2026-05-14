import 'package:cloud_firestore/cloud_firestore.dart';

enum SeasonStatus { upcoming, active, finished }

extension SeasonStatusExtension on SeasonStatus {
  String get displayName {
    switch (this) {
      case SeasonStatus.upcoming:
        return 'Upcoming';
      case SeasonStatus.active:
        return 'Active';
      case SeasonStatus.finished:
        return 'Finished';
    }
  }

  String get value {
    switch (this) {
      case SeasonStatus.upcoming:
        return 'upcoming';
      case SeasonStatus.active:
        return 'active';
      case SeasonStatus.finished:
        return 'finished';
    }
  }

  static SeasonStatus fromString(String value) {
    switch (value) {
      case 'active':
        return SeasonStatus.active;
      case 'finished':
        return SeasonStatus.finished;
      default:
        return SeasonStatus.upcoming;
    }
  }
}

class SeasonModel {
  final String id;
  final String tournamentId;
  final String name;
  final String? description;
  final SeasonStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? registrationDeadline;
  final int maxTeams;
  final int registeredTeams;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SeasonModel({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.description,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.registrationDeadline,
    required this.maxTeams,
    this.registeredTeams = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRegistrationOpen {
    if (registrationDeadline == null) return status == SeasonStatus.upcoming;
    return DateTime.now().isBefore(registrationDeadline!) &&
        status == SeasonStatus.upcoming;
  }

  bool get isFull => registeredTeams >= maxTeams;

  factory SeasonModel.fromJson(Map<String, dynamic> json, String id) {
    return SeasonModel(
      id: id,
      tournamentId: json['tournamentId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: SeasonStatusExtension.fromString(json['status'] as String? ?? ''),
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      registrationDeadline:
          (json['registrationDeadline'] as Timestamp?)?.toDate(),
      maxTeams: json['maxTeams'] as int? ?? 16,
      registeredTeams: json['registeredTeams'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tournamentId': tournamentId,
        'name': name,
        'description': description,
        'status': status.value,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'registrationDeadline': registrationDeadline != null
            ? Timestamp.fromDate(registrationDeadline!)
            : null,
        'maxTeams': maxTeams,
        'registeredTeams': registeredTeams,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  SeasonModel copyWith({
    String? name,
    String? description,
    SeasonStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    int? maxTeams,
    int? registeredTeams,
    DateTime? updatedAt,
  }) {
    return SeasonModel(
      id: id,
      tournamentId: tournamentId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      maxTeams: maxTeams ?? this.maxTeams,
      registeredTeams: registeredTeams ?? this.registeredTeams,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
