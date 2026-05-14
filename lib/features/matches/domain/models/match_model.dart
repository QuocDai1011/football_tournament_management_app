import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus { scheduled, live, finished, postponed, cancelled }
enum MatchType { groupStage, knockoutStage, semiFinal, thirdPlace, final_ }

extension MatchStatusExtension on MatchStatus {
  String get displayName {
    switch (this) {
      case MatchStatus.scheduled: return 'Scheduled';
      case MatchStatus.live: return 'LIVE';
      case MatchStatus.finished: return 'Finished';
      case MatchStatus.postponed: return 'Postponed';
      case MatchStatus.cancelled: return 'Cancelled';
    }
  }

  String get value {
    switch (this) {
      case MatchStatus.scheduled: return 'scheduled';
      case MatchStatus.live: return 'live';
      case MatchStatus.finished: return 'finished';
      case MatchStatus.postponed: return 'postponed';
      case MatchStatus.cancelled: return 'cancelled';
    }
  }

  static MatchStatus fromString(String value) {
    switch (value) {
      case 'live': return MatchStatus.live;
      case 'finished': return MatchStatus.finished;
      case 'postponed': return MatchStatus.postponed;
      case 'cancelled': return MatchStatus.cancelled;
      default: return MatchStatus.scheduled;
    }
  }
}

extension MatchTypeExtension on MatchType {
  String get displayName {
    switch (this) {
      case MatchType.groupStage: return 'Group Stage';
      case MatchType.knockoutStage: return 'Knockout Stage';
      case MatchType.semiFinal: return 'Semi Final';
      case MatchType.thirdPlace: return '3rd Place';
      case MatchType.final_: return 'Final';
    }
  }

  String get value {
    switch (this) {
      case MatchType.groupStage: return 'group_stage';
      case MatchType.knockoutStage: return 'knockout_stage';
      case MatchType.semiFinal: return 'semi_final';
      case MatchType.thirdPlace: return 'third_place';
      case MatchType.final_: return 'final';
    }
  }

  static MatchType fromString(String value) {
    switch (value) {
      case 'knockout_stage': return MatchType.knockoutStage;
      case 'semi_final': return MatchType.semiFinal;
      case 'third_place': return MatchType.thirdPlace;
      case 'final': return MatchType.final_;
      default: return MatchType.groupStage;
    }
  }
}

class MatchModel {
  final String id;
  final String tournamentId;
  final String? seasonId;
  final String homeTeamId;
  final String homeTeamName; // Denormalized
  final String? homeTeamLogoUrl; // Denormalized
  final String awayTeamId;
  final String awayTeamName; // Denormalized
  final String? awayTeamLogoUrl; // Denormalized
  final int homeScore;
  final int awayScore;
  final MatchStatus status;
  final MatchType type;
  final String? group;
  final int? round;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final String? venue;
  final int? minute; // current minute if live
  final DateTime createdAt;
  final DateTime updatedAt;

  const MatchModel({
    required this.id,
    required this.tournamentId,
    this.seasonId,
    required this.homeTeamId,
    required this.homeTeamName,
    this.homeTeamLogoUrl,
    required this.awayTeamId,
    required this.awayTeamName,
    this.awayTeamLogoUrl,
    this.homeScore = 0,
    this.awayScore = 0,
    required this.status,
    required this.type,
    this.group,
    this.round,
    this.scheduledAt,
    this.startedAt,
    this.venue,
    this.minute,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLive => status == MatchStatus.live;
  bool get isFinished => status == MatchStatus.finished;
  String get scoreDisplay => '$homeScore - $awayScore';

  factory MatchModel.fromJson(Map<String, dynamic> json, String id) {
    return MatchModel(
      id: id,
      tournamentId: json['tournamentId'] as String,
      seasonId: json['seasonId'] as String?,
      homeTeamId: json['homeTeamId'] as String,
      homeTeamName: json['homeTeamName'] as String? ?? '',
      homeTeamLogoUrl: json['homeTeamLogoUrl'] as String?,
      awayTeamId: json['awayTeamId'] as String,
      awayTeamName: json['awayTeamName'] as String? ?? '',
      awayTeamLogoUrl: json['awayTeamLogoUrl'] as String?,
      homeScore: json['homeScore'] as int? ?? 0,
      awayScore: json['awayScore'] as int? ?? 0,
      status: MatchStatusExtension.fromString(json['status'] as String? ?? ''),
      type: MatchTypeExtension.fromString(json['type'] as String? ?? ''),
      group: json['group'] as String?,
      round: json['round'] as int?,
      scheduledAt: (json['scheduledAt'] as Timestamp?)?.toDate(),
      startedAt: (json['startedAt'] as Timestamp?)?.toDate(),
      venue: json['venue'] as String?,
      minute: json['minute'] as int?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'tournamentId': tournamentId,
    'seasonId': seasonId,
    'homeTeamId': homeTeamId,
    'homeTeamName': homeTeamName,
    'homeTeamLogoUrl': homeTeamLogoUrl,
    'awayTeamId': awayTeamId,
    'awayTeamName': awayTeamName,
    'awayTeamLogoUrl': awayTeamLogoUrl,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'status': status.value,
    'type': type.value,
    'group': group,
    'round': round,
    'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
    'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
    'venue': venue,
    'minute': minute,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  MatchModel copyWith({
    int? homeScore,
    int? awayScore,
    MatchStatus? status,
    int? minute,
    String? venue,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? updatedAt,
  }) {
    return MatchModel(
      id: id,
      tournamentId: tournamentId,
      seasonId: seasonId,
      homeTeamId: homeTeamId,
      homeTeamName: homeTeamName,
      homeTeamLogoUrl: homeTeamLogoUrl,
      awayTeamId: awayTeamId,
      awayTeamName: awayTeamName,
      awayTeamLogoUrl: awayTeamLogoUrl,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      type: type,
      group: group,
      round: round,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      venue: venue ?? this.venue,
      minute: minute ?? this.minute,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ---- Match Events ----
enum MatchEventType { goal, ownGoal, penalty, yellowCard, redCard, substitution }

extension MatchEventTypeExtension on MatchEventType {
  String get displayName {
    switch (this) {
      case MatchEventType.goal: return 'Goal';
      case MatchEventType.ownGoal: return 'Own Goal';
      case MatchEventType.penalty: return 'Penalty';
      case MatchEventType.yellowCard: return 'Yellow Card';
      case MatchEventType.redCard: return 'Red Card';
      case MatchEventType.substitution: return 'Substitution';
    }
  }

  String get value {
    switch (this) {
      case MatchEventType.goal: return 'goal';
      case MatchEventType.ownGoal: return 'own_goal';
      case MatchEventType.penalty: return 'penalty';
      case MatchEventType.yellowCard: return 'yellow_card';
      case MatchEventType.redCard: return 'red_card';
      case MatchEventType.substitution: return 'substitution';
    }
  }

  static MatchEventType fromString(String value) {
    switch (value) {
      case 'own_goal': return MatchEventType.ownGoal;
      case 'penalty': return MatchEventType.penalty;
      case 'yellow_card': return MatchEventType.yellowCard;
      case 'red_card': return MatchEventType.redCard;
      case 'substitution': return MatchEventType.substitution;
      default: return MatchEventType.goal;
    }
  }
}

class MatchEvent {
  final String id;
  final String matchId;
  final MatchEventType type;
  final int minute;
  final String teamId;
  final String playerId;
  final String playerName;
  final String? assistPlayerId;
  final String? assistPlayerName;
  final String? substitutedPlayerId;
  final String? substitutedPlayerName;
  final bool isHomeTeam;
  final DateTime createdAt;

  const MatchEvent({
    required this.id,
    required this.matchId,
    required this.type,
    required this.minute,
    required this.teamId,
    required this.playerId,
    required this.playerName,
    this.assistPlayerId,
    this.assistPlayerName,
    this.substitutedPlayerId,
    this.substitutedPlayerName,
    required this.isHomeTeam,
    required this.createdAt,
  });

  factory MatchEvent.fromJson(Map<String, dynamic> json, String id) {
    return MatchEvent(
      id: id,
      matchId: json['matchId'] as String,
      type: MatchEventTypeExtension.fromString(json['type'] as String? ?? 'goal'),
      minute: json['minute'] as int? ?? 0,
      teamId: json['teamId'] as String,
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String? ?? '',
      assistPlayerId: json['assistPlayerId'] as String?,
      assistPlayerName: json['assistPlayerName'] as String?,
      substitutedPlayerId: json['substitutedPlayerId'] as String?,
      substitutedPlayerName: json['substitutedPlayerName'] as String?,
      isHomeTeam: json['isHomeTeam'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'matchId': matchId,
    'type': type.value,
    'minute': minute,
    'teamId': teamId,
    'playerId': playerId,
    'playerName': playerName,
    'assistPlayerId': assistPlayerId,
    'assistPlayerName': assistPlayerName,
    'substitutedPlayerId': substitutedPlayerId,
    'substitutedPlayerName': substitutedPlayerName,
    'isHomeTeam': isHomeTeam,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
