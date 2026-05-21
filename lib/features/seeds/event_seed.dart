import 'package:faker/faker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// types: goal, own_goal, yellow_card, red_card, substitution
const List<String> eventTypes = [
  'goal',
  'own_goal',
  'yellow_card',
  'red_card',
  'substitution'
];

Map<String, dynamic> randomEvent(Faker faker,
    {required String playerId, required String teamId, int minuteMax = 120}) {
  final rnd = faker.randomGenerator;
  final type = eventTypes[rnd.integer(eventTypes.length)];
  final minute = rnd.integer(minuteMax, min: 1);

  return {
    'minute': minute,
    'playerId': playerId,
    'teamId': teamId,
    'type': type,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
