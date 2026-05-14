import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/date_utils.dart';

class TeamModel {
  final String id;
  final String name;
  final String? shortName;
  final String? logoUrl;
  final String? logoPublicId;
  final String? homeColor;
  final String? awayColor;
  final String? city;
  final String? coach;
  final DateTime? foundedYear;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Denormalized stats for quick access
  final int totalPlayers;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;

  const TeamModel({
    required this.id,
    required this.name,
    this.shortName,
    this.logoUrl,
    this.logoPublicId,
    this.homeColor,
    this.awayColor,
    this.city,
    this.coach,
    this.foundedYear,
    required this.createdAt,
    required this.updatedAt,
    this.totalPlayers = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;
  int get totalGames => wins + draws + losses;

  factory TeamModel.fromJson(Map<String, dynamic> json, String id) {
    return TeamModel(
      id: id,
      name: json['name'] as String,
      shortName: json['shortName'] as String?,
      logoUrl: json['logoUrl'] as String?,
      logoPublicId: json['logoPublicId'] as String?,
      homeColor: json['homeColor'] as String?,
      awayColor: json['awayColor'] as String?,
      city: json['city'] as String?,
      coach: json['coach'] as String?,
      foundedYear: AppDateUtils.parseDate(json['foundedYear']),
      createdAt: AppDateUtils.parseDateOrNow(json['createdAt']),
      updatedAt: AppDateUtils.parseDateOrNow(json['updatedAt']),
      totalPlayers: json['totalPlayers'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      goalsFor: json['goalsFor'] as int? ?? 0,
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'shortName': shortName,
        'logoUrl': logoUrl,
        'logoPublicId': logoPublicId,
        'homeColor': homeColor,
        'awayColor': awayColor,
        'city': city,
        'coach': coach,
        'foundedYear': AppDateUtils.toTimestampOrNull(foundedYear),
        'createdAt': AppDateUtils.toTimestamp(createdAt),
        'updatedAt': AppDateUtils.toTimestamp(updatedAt),
        'totalPlayers': totalPlayers,
        'wins': wins,
        'draws': draws,
        'losses': losses,
        'goalsFor': goalsFor,
        'goalsAgainst': goalsAgainst,
      };

  TeamModel copyWith({
    String? name,
    String? shortName,
    String? logoUrl,
    String? logoPublicId,
    String? homeColor,
    String? awayColor,
    String? city,
    String? coach,
    DateTime? foundedYear,
    DateTime? updatedAt,
    int? totalPlayers,
    int? wins,
    int? draws,
    int? losses,
    int? goalsFor,
    int? goalsAgainst,
  }) {
    return TeamModel(
      id: id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logoUrl: logoUrl ?? this.logoUrl,
      logoPublicId: logoPublicId ?? this.logoPublicId,
      homeColor: homeColor ?? this.homeColor,
      awayColor: awayColor ?? this.awayColor,
      city: city ?? this.city,
      coach: coach ?? this.coach,
      foundedYear: foundedYear ?? this.foundedYear,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalPlayers: totalPlayers ?? this.totalPlayers,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
