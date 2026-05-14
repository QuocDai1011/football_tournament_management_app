import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/date_utils.dart';

enum PlayerPosition { gk, df, mf, fw }

extension PlayerPositionExtension on PlayerPosition {
  String get displayName {
    switch (this) {
      case PlayerPosition.gk:
        return 'Goalkeeper';
      case PlayerPosition.df:
        return 'Defender';
      case PlayerPosition.mf:
        return 'Midfielder';
      case PlayerPosition.fw:
        return 'Forward';
    }
  }

  String get abbreviation {
    switch (this) {
      case PlayerPosition.gk:
        return 'GK';
      case PlayerPosition.df:
        return 'DF';
      case PlayerPosition.mf:
        return 'MF';
      case PlayerPosition.fw:
        return 'FW';
    }
  }

  String get value {
    switch (this) {
      case PlayerPosition.gk:
        return 'gk';
      case PlayerPosition.df:
        return 'df';
      case PlayerPosition.mf:
        return 'mf';
      case PlayerPosition.fw:
        return 'fw';
    }
  }

  static PlayerPosition fromString(String value) {
    switch (value) {
      case 'df':
        return PlayerPosition.df;
      case 'mf':
        return PlayerPosition.mf;
      case 'fw':
        return PlayerPosition.fw;
      default:
        return PlayerPosition.gk;
    }
  }
}

class PlayerModel {
  final String id;
  final String name;
  final String teamId;
  final String? teamName; // Denormalized for display
  final PlayerPosition position;
  final int shirtNumber;
  final bool isCaptain;
  final String? avatarUrl;
  final String? avatarPublicId;
  final DateTime? dateOfBirth;
  final String? nationality;
  final int? height; // cm
  final int? weight; // kg
  final DateTime createdAt;
  final DateTime updatedAt;
  // Denormalized stats
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int appearances;
  final int cleanSheets; // For GK

  const PlayerModel({
    required this.id,
    required this.name,
    required this.teamId,
    this.teamName,
    required this.position,
    required this.shirtNumber,
    this.isCaptain = false,
    this.avatarUrl,
    this.avatarPublicId,
    this.dateOfBirth,
    this.nationality,
    this.height,
    this.weight,
    required this.createdAt,
    required this.updatedAt,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.appearances = 0,
    this.cleanSheets = 0,
  });

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  factory PlayerModel.fromJson(Map<String, dynamic> json, String id) {
    return PlayerModel(
      id: id,
      name: json['name'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String?,
      position: PlayerPositionExtension.fromString(
          json['position'] as String? ?? 'gk'),
      shirtNumber: json['shirtNumber'] as int? ?? 0,
      isCaptain: json['isCaptain'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
      avatarPublicId: json['avatarPublicId'] as String?,
      dateOfBirth: AppDateUtils.parseDate(json['dateOfBirth']),
      nationality: json['nationality'] as String?,
      height: json['height'] as int?,
      weight: json['weight'] as int?,
      createdAt: AppDateUtils.parseDateOrNow(json['createdAt']),
      updatedAt: AppDateUtils.parseDateOrNow(json['updatedAt']),
      goals: json['goals'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      yellowCards: json['yellowCards'] as int? ?? 0,
      redCards: json['redCards'] as int? ?? 0,
      appearances: json['appearances'] as int? ?? 0,
      cleanSheets: json['cleanSheets'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'teamId': teamId,
        'teamName': teamName,
        'position': position.value,
        'shirtNumber': shirtNumber,
        'isCaptain': isCaptain,
        'avatarUrl': avatarUrl,
        'avatarPublicId': avatarPublicId,
        'dateOfBirth':
            dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
        'nationality': nationality,
        'height': height,
        'weight': weight,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'goals': goals,
        'assists': assists,
        'yellowCards': yellowCards,
        'redCards': redCards,
        'appearances': appearances,
        'cleanSheets': cleanSheets,
      };

  PlayerModel copyWith({
    String? name,
    String? teamId,
    String? teamName,
    PlayerPosition? position,
    int? shirtNumber,
    bool? isCaptain,
    String? avatarUrl,
    String? avatarPublicId,
    DateTime? dateOfBirth,
    String? nationality,
    int? height,
    int? weight,
    DateTime? updatedAt,
    int? goals,
    int? assists,
    int? yellowCards,
    int? redCards,
    int? appearances,
    int? cleanSheets,
  }) {
    return PlayerModel(
      id: id,
      name: name ?? this.name,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      position: position ?? this.position,
      shirtNumber: shirtNumber ?? this.shirtNumber,
      isCaptain: isCaptain ?? this.isCaptain,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarPublicId: avatarPublicId ?? this.avatarPublicId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      appearances: appearances ?? this.appearances,
      cleanSheets: cleanSheets ?? this.cleanSheets,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
