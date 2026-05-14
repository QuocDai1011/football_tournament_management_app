import 'dart:math';

/// Fixture generator algorithms for tournament scheduling
class FixtureGenerator {
  FixtureGenerator._();

  /// Round-robin algorithm (each team plays every other team once)
  /// Returns list of (homeTeamId, awayTeamId, roundNumber)
  static List<(String, String, int)> roundRobin(List<String> teams) {
    final List<(String, String, int)> fixtures = [];
    final n = teams.length;
    final teamList = List<String>.from(teams);

    // Add a bye if odd number of teams
    if (n % 2 != 0) teamList.add('BYE');
    final totalTeams = teamList.length;
    final totalRounds = totalTeams - 1;
    final matchesPerRound = totalTeams ~/ 2;

    for (int round = 0; round < totalRounds; round++) {
      for (int match = 0; match < matchesPerRound; match++) {
        final home = teamList[match];
        final away = teamList[totalTeams - 1 - match];
        if (home != 'BYE' && away != 'BYE') {
          // Alternate home/away
          if (round % 2 == 0) {
            fixtures.add((home, away, round + 1));
          } else {
            fixtures.add((away, home, round + 1));
          }
        }
      }
      // Rotate teams (keep first team fixed)
      final last = teamList.removeAt(teamList.length - 1);
      teamList.insert(1, last);
    }

    return fixtures;
  }

  /// Double round-robin (home and away)
  static List<(String, String, int)> doubleRoundRobin(List<String> teams) {
    final firstLeg = roundRobin(teams);
    final secondLeg = firstLeg
        .map((f) => (f.$2, f.$1, f.$3 + firstLeg.length))
        .toList();
    return [...firstLeg, ...secondLeg];
  }

  /// Knockout bracket generation
  /// Returns rounds of matches in bracket order
  static List<List<(String, String)>> knockout(List<String> teams) {
    final shuffled = List<String>.from(teams)..shuffle(Random());
    final rounds = <List<(String, String)>>[];

    var current = shuffled;
    while (current.length > 1) {
      final round = <(String, String)>[];
      final padded = _padToPowerOfTwo(current);
      for (int i = 0; i < padded.length; i += 2) {
        if (padded[i] != 'BYE' && padded[i + 1] != 'BYE') {
          round.add((padded[i], padded[i + 1]));
        }
      }
      rounds.add(round);
      // Next round winners (placeholder IDs)
      current = List.generate(
        (current.length / 2).ceil(),
        (i) => 'TBD_$i',
      );
    }
    return rounds;
  }

  static List<String> _padToPowerOfTwo(List<String> teams) {
    int size = 1;
    while (size < teams.length) size *= 2;
    return [...teams, ...List.filled(size - teams.length, 'BYE')];
  }

  /// Group stage assignment
  static Map<String, List<String>> assignGroups(
    List<String> teams,
    int numberOfGroups,
  ) {
    final shuffled = List<String>.from(teams)..shuffle();
    final groups = <String, List<String>>{};

    for (int i = 0; i < numberOfGroups; i++) {
      groups[String.fromCharCode(65 + i)] = [];
    }

    for (int i = 0; i < shuffled.length; i++) {
      final groupKey = String.fromCharCode(65 + (i % numberOfGroups));
      groups[groupKey]!.add(shuffled[i]);
    }

    return groups;
  }
}
