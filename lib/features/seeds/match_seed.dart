import 'package:faker/faker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_seed.dart';

const List<String> matchStatuses = [
  'scheduled',
  'live',
  'finished',
  'postponed'
];

Future<List<Map<String, dynamic>>> generateMatches(
  FirebaseFirestore firestore,
  List<Map<String, dynamic>> teams,
  List<Map<String, dynamic>> tournaments,
  List<Map<String, dynamic>> players, {
  int count = 50,
  Faker? faker,
}) async {
  faker ??= Faker();
  final collection = firestore.collection('matches');
  final rnd = faker.randomGenerator;
  final List<Map<String, dynamic>> matches = [];

  for (var i = 0; i < count; i++) {
    // pick distinct teams
    final home = teams[rnd.integer(teams.length)];
    Map<String, dynamic> away;
    do {
      away = teams[rnd.integer(teams.length)];
    } while (away['id'] == home['id']);

    final docRef = collection.doc();
    final tournament = tournaments.isNotEmpty
        ? tournaments[rnd.integer(tournaments.length)]
        : null;

    final status = matchStatuses[rnd.integer(matchStatuses.length)];
    final kickoff =
        DateTime.now().add(Duration(days: rnd.integer(60, min: -30)));

    int homeGoals = 0;
    int awayGoals = 0;
    if (status == 'finished') {
      homeGoals = rnd.integer(5);
      awayGoals = rnd.integer(5);
    }

    // events will be generated later; here we prepare a placeholder
    final matchData = {
      'homeTeamId': home['id'],
      'homeTeamName': home['data']['name'],
      'awayTeamId': away['id'],
      'awayTeamName': away['data']['name'],
      'tournamentId': tournament != null ? tournament['id'] : null,
      'score': {
        'home': homeGoals,
        'away': awayGoals,
      },
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'kickoffTime': Timestamp.fromDate(kickoff),
    };

    // generate events based on goals/cards/subs
    final List<Map<String, dynamic>> events = [];

    // choose players from teams
    final homePlayers =
        players.where((p) => p['data']['teamId'] == home['id']).toList();
    final awayPlayers =
        players.where((p) => p['data']['teamId'] == away['id']).toList();

    // goals events
    for (var g = 0; g < homeGoals; g++) {
      final scorer = homePlayers.isNotEmpty
          ? homePlayers[rnd.integer(homePlayers.length)]['id']
          : null;
      if (scorer != null) {
        events.add(randomEvent(faker, playerId: scorer, teamId: home['id']));
      }
    }
    for (var g = 0; g < awayGoals; g++) {
      final scorer = awayPlayers.isNotEmpty
          ? awayPlayers[rnd.integer(awayPlayers.length)]['id']
          : null;
      if (scorer != null) {
        events.add(randomEvent(faker, playerId: scorer, teamId: away['id']));
      }
    }

    // random cards
    final cardCount = rnd.integer(4);
    for (var c = 0; c < cardCount; c++) {
      final isHome = rnd.boolean();
      final list = isHome ? homePlayers : awayPlayers;
      if (list.isEmpty) continue;
      final p = list[rnd.integer(list.length)]['id'];
      events.add(randomEvent(faker,
          playerId: p, teamId: isHome ? home['id'] : away['id']));
    }

    // random substitutions
    final subs = rnd.integer(3);
    for (var s = 0; s < subs; s++) {
      final isHome = rnd.boolean();
      final list = isHome ? homePlayers : awayPlayers;
      if (list.isEmpty) continue;
      final p = list[rnd.integer(list.length)]['id'];
      events.add(randomEvent(faker,
          playerId: p, teamId: isHome ? home['id'] : away['id']));
    }

    matches.add({
      'id': docRef.id,
      'ref': docRef,
      'data': matchData,
      'events': events,
    });
  }

  return matches;
}
