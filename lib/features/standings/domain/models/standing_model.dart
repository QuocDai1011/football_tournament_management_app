import 'package:cloud_firestore/cloud_firestore.dart';

/// Standing entry for a team in a tournament/group
class StandingModel {
  final String id;
  final String tournamentId;
  final String? seasonId;
  final String? group;
  final String teamId;
  final String teamName; // Denormalized
  final String? teamLogoUrl; // Denormalized
  final int position;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  final DateTime updatedAt;

  const StandingModel({
    required this.id,
    required this.tournamentId,
    this.seasonId,
    this.group,
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    required this.position,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
    required this.updatedAt,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  factory StandingModel.fromJson(Map<String, dynamic> json, String id) {
    return StandingModel(
      id: id,
      tournamentId: json['tournamentId'] as String,
      seasonId: json['seasonId'] as String?,
      group: json['group'] as String?,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String? ?? '',
      teamLogoUrl: json['teamLogoUrl'] as String?,
      position: json['position'] as int? ?? 0,
      played: json['played'] as int? ?? 0,
      won: json['won'] as int? ?? 0,
      drawn: json['drawn'] as int? ?? 0,
      lost: json['lost'] as int? ?? 0,
      goalsFor: json['goalsFor'] as int? ?? 0,
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'tournamentId': tournamentId,
    'seasonId': seasonId,
    'group': group,
    'teamId': teamId,
    'teamName': teamName,
    'teamLogoUrl': teamLogoUrl,
    'position': position,
    'played': played,
    'won': won,
    'drawn': drawn,
    'lost': lost,
    'goalsFor': goalsFor,
    'goalsAgainst': goalsAgainst,
    'points': points,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  StandingModel copyWith({
    int? position,
    int? played,
    int? won,
    int? drawn,
    int? lost,
    int? goalsFor,
    int? goalsAgainst,
    int? points,
    DateTime? updatedAt,
  }) {
    return StandingModel(
      id: id,
      tournamentId: tournamentId,
      seasonId: seasonId,
      group: group,
      teamId: teamId,
      teamName: teamName,
      teamLogoUrl: teamLogoUrl,
      position: position ?? this.position,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      points: points ?? this.points,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StandingModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Award model
enum AwardType { champion, runnerUp, topScorer, bestGoalkeeper, fairPlay }

extension AwardTypeExtension on AwardType {
  String get displayName {
    switch (this) {
      case AwardType.champion: return 'Champion';
      case AwardType.runnerUp: return 'Runner-Up';
      case AwardType.topScorer: return 'Top Scorer';
      case AwardType.bestGoalkeeper: return 'Best Goalkeeper';
      case AwardType.fairPlay: return 'Fair Play';
    }
  }

  String get value {
    switch (this) {
      case AwardType.champion: return 'champion';
      case AwardType.runnerUp: return 'runner_up';
      case AwardType.topScorer: return 'top_scorer';
      case AwardType.bestGoalkeeper: return 'best_goalkeeper';
      case AwardType.fairPlay: return 'fair_play';
    }
  }

  static AwardType fromString(String value) {
    switch (value) {
      case 'runner_up': return AwardType.runnerUp;
      case 'top_scorer': return AwardType.topScorer;
      case 'best_goalkeeper': return AwardType.bestGoalkeeper;
      case 'fair_play': return AwardType.fairPlay;
      default: return AwardType.champion;
    }
  }
}

class AwardModel {
  final String id;
  final String tournamentId;
  final String? seasonId;
  final AwardType type;
  final String? teamId;
  final String? teamName;
  final String? playerId;
  final String? playerName;
  final int? statValue; // Goals for top scorer, etc.
  final DateTime createdAt;

  const AwardModel({
    required this.id,
    required this.tournamentId,
    this.seasonId,
    required this.type,
    this.teamId,
    this.teamName,
    this.playerId,
    this.playerName,
    this.statValue,
    required this.createdAt,
  });

  factory AwardModel.fromJson(Map<String, dynamic> json, String id) {
    return AwardModel(
      id: id,
      tournamentId: json['tournamentId'] as String,
      seasonId: json['seasonId'] as String?,
      type: AwardTypeExtension.fromString(json['type'] as String? ?? ''),
      teamId: json['teamId'] as String?,
      teamName: json['teamName'] as String?,
      playerId: json['playerId'] as String?,
      playerName: json['playerName'] as String?,
      statValue: json['statValue'] as int?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'tournamentId': tournamentId,
    'seasonId': seasonId,
    'type': type.value,
    'teamId': teamId,
    'teamName': teamName,
    'playerId': playerId,
    'playerName': playerName,
    'statValue': statValue,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
