import '../../../features/matches/domain/models/match_model.dart';
import '../../../features/standings/domain/models/standing_model.dart';
import '../../../features/tournaments/domain/models/tournament_model.dart';

/// Standings calculation engine
/// Computes league table from a list of completed matches
class StandingsEngine {
  StandingsEngine._();

  /// Calculate standings from finished matches
  static List<StandingModel> calculate({
    required String tournamentId,
    required List<MatchModel> matches,
    required ScoringSystem scoring,
    String? seasonId,
    String? group,
  }) {
    final Map<String, StandingModel> table = {};

    for (final match in matches) {
      if (match.status != MatchStatus.finished) continue;

      final homeId = match.homeTeamId;
      final awayId = match.awayTeamId;

      // Initialize standings if missing
      table.putIfAbsent(
        homeId,
        () => StandingModel(
          id: homeId,
          tournamentId: tournamentId,
          seasonId: seasonId,
          group: group,
          teamId: homeId,
          teamName: match.homeTeamName,
          teamLogoUrl: match.homeTeamLogoUrl,
          position: 0,
          updatedAt: DateTime.now(),
        ),
      );
      table.putIfAbsent(
        awayId,
        () => StandingModel(
          id: awayId,
          tournamentId: tournamentId,
          seasonId: seasonId,
          group: group,
          teamId: awayId,
          teamName: match.awayTeamName,
          teamLogoUrl: match.awayTeamLogoUrl,
          position: 0,
          updatedAt: DateTime.now(),
        ),
      );

      final home = table[homeId]!;
      final away = table[awayId]!;

      final homeGoals = match.homeScore;
      final awayGoals = match.awayScore;

      // Determine result
      int homePoints, awayPoints;
      int homeW = 0, homeD = 0, homeL = 0;
      int awayW = 0, awayD = 0, awayL = 0;

      if (homeGoals > awayGoals) {
        homePoints = scoring.win;
        awayPoints = scoring.loss;
        homeW = 1;
        awayL = 1;
      } else if (homeGoals == awayGoals) {
        homePoints = scoring.draw;
        awayPoints = scoring.draw;
        homeD = 1;
        awayD = 1;
      } else {
        homePoints = scoring.loss;
        awayPoints = scoring.win;
        homeL = 1;
        awayW = 1;
      }

      // Update home team
      table[homeId] = home.copyWith(
        played: home.played + 1,
        won: home.won + homeW,
        drawn: home.drawn + homeD,
        lost: home.lost + homeL,
        goalsFor: home.goalsFor + homeGoals,
        goalsAgainst: home.goalsAgainst + awayGoals,
        points: home.points + homePoints,
        updatedAt: DateTime.now(),
      );

      // Update away team
      table[awayId] = away.copyWith(
        played: away.played + 1,
        won: away.won + awayW,
        drawn: away.drawn + awayD,
        lost: away.lost + awayL,
        goalsFor: away.goalsFor + awayGoals,
        goalsAgainst: away.goalsAgainst + homeGoals,
        points: away.points + awayPoints,
        updatedAt: DateTime.now(),
      );
    }

    // Sort by: Points → Goal Difference → Goals For → Team Name
    final sorted = table.values.toList()
      ..sort((a, b) {
        if (b.points != a.points) return b.points.compareTo(a.points);
        if (b.goalDifference != a.goalDifference) {
          return b.goalDifference.compareTo(a.goalDifference);
        }
        if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);
        return a.teamName.compareTo(b.teamName);
      });

    // Assign positions
    return sorted
        .asMap()
        .entries
        .map((e) => e.value.copyWith(position: e.key + 1))
        .toList();
  }

  /// Calculate top scorers from player stats
  static List<_PlayerStat> topScorers(List<_PlayerStat> players) {
    return (players..sort((a, b) => b.goals.compareTo(a.goals)));
  }
}

class _PlayerStat {
  final String playerId;
  final String playerName;
  final String teamName;
  final int goals;
  final int assists;

  const _PlayerStat({
    required this.playerId,
    required this.playerName,
    required this.teamName,
    required this.goals,
    this.assists = 0,
  });
}
