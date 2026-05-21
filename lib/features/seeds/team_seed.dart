import 'package:faker/faker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Generate team entries (not written to Firestore here).
Future<List<Map<String, dynamic>>> generateTeams(
  FirebaseFirestore firestore, {
  int count = 20,
  Faker? faker,
}) async {
  faker ??= Faker();
  final collection = firestore.collection('teams');
  final List<Map<String, dynamic>> teams = [];

  for (var i = 0; i < count; i++) {
    final docRef = collection.doc();
    final name = faker.company.name();
    final short = name.split(' ').map((s) => s[0]).take(3).join();
    final rand = faker.randomGenerator;
    teams.add({
      'id': docRef.id,
      'ref': docRef,
      'data': {
        'name': name,
        'shortName': short,
        'city': faker.address.city(),
        'logoUrl': null,
        'homeColor':
            '#${rand.integer(0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'totalPlayers': 0,
        'wins': 0,
        'draws': 0,
        'losses': 0,
        'goalsFor': 0,
        'goalsAgainst': 0,
      }
    });
  }

  return teams;
}
