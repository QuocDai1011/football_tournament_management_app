import 'package:faker/faker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> _positions = ['gk', 'df', 'mf', 'fw'];

/// Generate player entries referencing teams. Returns list of maps {id, ref, data}
Future<List<Map<String, dynamic>>> generatePlayers(
  FirebaseFirestore firestore,
  List<Map<String, dynamic>> teams, {
  int count = 200,
  Faker? faker,
}) async {
  faker ??= Faker();
  final collection = firestore.collection('players');
  final rand = faker.randomGenerator;
  final List<Map<String, dynamic>> players = [];

  for (var i = 0; i < count; i++) {
    final docRef = collection.doc();
    final team = teams[rand.integer(teams.length)];
    final position = _positions[rand.integer(_positions.length)];
    final name = faker.person.name();
    players.add({
      'id': docRef.id,
      'ref': docRef,
      'data': {
        'name': name,
        'teamId': team['id'],
        'teamName': team['data']['name'],
        'position': position,
        'shirtNumber': rand.integer(99, min: 1),
        'isCaptain': rand.decimal() > 0.95,
        'avatarUrl': null,
        'avatarPublicId': null,
        'dateOfBirth': null,
        'nationality': faker.address.country(),
        'height': 165 + rand.integer(40),
        'weight': 60 + rand.integer(40),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // stats
        'goals': 0,
        'assists': 0,
        'yellowCards': 0,
        'redCards': 0,
        'appearances': 0,
        'cleanSheets': 0,
      }
    });
  }

  return players;
}
