import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/date_utils.dart';

enum TournamentType { league, knockout, hybrid }

enum TournamentStatus { upcoming, ongoing, finished }

extension TournamentTypeExtension on TournamentType {
  String get displayName {
    switch (this) {
      case TournamentType.league:
        return 'League';
      case TournamentType.knockout:
        return 'Knockout';
      case TournamentType.hybrid:
        return 'Hybrid';
    }
  }

  String get value {
    switch (this) {
      case TournamentType.league:
        return 'league';
      case TournamentType.knockout:
        return 'knockout';
      case TournamentType.hybrid:
        return 'hybrid';
    }
  }

  static TournamentType fromString(String value) {
    switch (value) {
      case 'knockout':
        return TournamentType.knockout;
      case 'hybrid':
        return TournamentType.hybrid;
      default:
        return TournamentType.league;
    }
  }
}

extension TournamentStatusExtension on TournamentStatus {
  String get displayName {
    switch (this) {
      case TournamentStatus.upcoming:
        return 'Upcoming';
      case TournamentStatus.ongoing:
        return 'Ongoing';
      case TournamentStatus.finished:
        return 'Finished';
    }
  }

  String get value {
    switch (this) {
      case TournamentStatus.upcoming:
        return 'upcoming';
      case TournamentStatus.ongoing:
        return 'ongoing';
      case TournamentStatus.finished:
        return 'finished';
    }
  }

  static TournamentStatus fromString(String value) {
    switch (value) {
      case 'ongoing':
        return TournamentStatus.ongoing;
      case 'finished':
        return TournamentStatus.finished;
      default:
        return TournamentStatus.upcoming;
    }
  }
}

class ScoringSystem {
  final int win;
  final int draw;
  final int loss;

  const ScoringSystem({
    this.win = 3,
    this.draw = 1,
    this.loss = 0,
  });

  factory ScoringSystem.fromJson(Map<String, dynamic> json) => ScoringSystem(
        win: json['win'] as int? ?? 3,
        draw: json['draw'] as int? ?? 1,
        loss: json['loss'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'win': win, 'draw': draw, 'loss': loss};
}

class TournamentModel {
  final String id;
  final String name;
  final String? description;
  final String? bannerUrl;
  final String? bannerPublicId;
  final TournamentType type;
  final TournamentStatus status;
  final int maxTeams;
  final int? numberOfGroups;
  final String? rules;
  final ScoringSystem scoringSystem;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalMatches;
  final int completedMatches;

  const TournamentModel({
    required this.id,
    required this.name,
    this.description,
    this.bannerUrl,
    this.bannerPublicId,
    required this.type,
    required this.status,
    required this.maxTeams,
    this.numberOfGroups,
    this.rules,
    required this.scoringSystem,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.totalMatches = 0,
    this.completedMatches = 0,
  });

  double get progressPercent =>
      totalMatches == 0 ? 0 : completedMatches / totalMatches;

  factory TournamentModel.fromJson(Map<String, dynamic> json, String id) {
    return TournamentModel(
      id: id,
      name: json['name'] as String,
      description: json['description'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      bannerPublicId: json['bannerPublicId'] as String?,
      type: TournamentTypeExtension.fromString(json['type'] as String? ?? ''),
      status:
          TournamentStatusExtension.fromString(json['status'] as String? ?? ''),
      maxTeams: json['maxTeams'] as int? ?? 16,
      numberOfGroups: json['numberOfGroups'] as int?,
      rules: json['rules'] as String?,
      scoringSystem: json['scoringSystem'] != null
          ? ScoringSystem.fromJson(
              json['scoringSystem'] as Map<String, dynamic>)
          : const ScoringSystem(),
      startDate: AppDateUtils.parseDate(json['startDate']),
      endDate: AppDateUtils.parseDate(json['endDate']),
      createdAt: AppDateUtils.parseDateOrNow(json['createdAt']),
      updatedAt: AppDateUtils.parseDateOrNow(json['updatedAt']),
      totalMatches: json['totalMatches'] as int? ?? 0,
      completedMatches: json['completedMatches'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'bannerUrl': bannerUrl,
        'bannerPublicId': bannerPublicId,
        'type': type.value,
        'status': status.value,
        'maxTeams': maxTeams,
        'numberOfGroups': numberOfGroups,
        'rules': rules,
        'scoringSystem': scoringSystem.toJson(),
        'startDate': AppDateUtils.toTimestampOrNull(startDate),
        'endDate': AppDateUtils.toTimestampOrNull(endDate),
        'createdAt': AppDateUtils.toTimestamp(createdAt),
        'updatedAt': AppDateUtils.toTimestamp(updatedAt),
        'totalMatches': totalMatches,
        'completedMatches': completedMatches,
      };

  TournamentModel copyWith({
    String? name,
    String? description,
    String? bannerUrl,
    String? bannerPublicId,
    TournamentType? type,
    TournamentStatus? status,
    int? maxTeams,
    int? numberOfGroups,
    String? rules,
    ScoringSystem? scoringSystem,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? updatedAt,
    int? totalMatches,
    int? completedMatches,
  }) {
    return TournamentModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bannerPublicId: bannerPublicId ?? this.bannerPublicId,
      type: type ?? this.type,
      status: status ?? this.status,
      maxTeams: maxTeams ?? this.maxTeams,
      numberOfGroups: numberOfGroups ?? this.numberOfGroups,
      rules: rules ?? this.rules,
      scoringSystem: scoringSystem ?? this.scoringSystem,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalMatches: totalMatches ?? this.totalMatches,
      completedMatches: completedMatches ?? this.completedMatches,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
