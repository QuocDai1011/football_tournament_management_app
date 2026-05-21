import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';

import 'team_seed.dart';
import 'player_seed.dart';
import 'match_seed.dart';

class SeedService {
  final FirebaseFirestore firestore;
  final Faker faker;
  SeedService({FirebaseFirestore? firestore, Faker? faker})
      : firestore = firestore ?? FirebaseFirestore.instance,
        faker = faker ?? Faker();

  static const int _batchLimit = 450; // keep below 500

  Future<void> generateFakeData({void Function(String)? onLog}) async {
    onLog?.call('Starting fake data generation');

    // 1. Teams
    onLog?.call('Generating teams');
    final teams = await generateTeams(firestore, faker: faker);
    await _writeIfNotExists(teams, onLog: onLog);

    // 2. Players
    onLog?.call('Generating players');
    final players = await generatePlayers(firestore, teams, faker: faker);
    await _writeIfNotExists(players, onLog: onLog);

    // Update team counts
    onLog?.call('Updating team player counts');
    await _updateTeamCounts(teams, players, onLog: onLog);

    // 3. Tournaments (simple small set)
    onLog?.call('Generating tournaments');
    final tournaments = await _generateTournaments();
    await _writeIfNotExists(tournaments,
        collectionName: 'tournaments', onLog: onLog);

    // 4. Matches + Events
    onLog?.call('Generating matches and events');
    final matches = await generateMatches(
        firestore, teams, tournaments, players,
        faker: faker);
    await _writeMatchesWithEvents(matches, onLog: onLog);

    // 5. Standings
    onLog?.call('Computing standings');
    final standings = _computeStandings(teams, matches);
    await _writeIfNotExists(standings,
        collectionName: 'standings', onLog: onLog);

    onLog?.call('Fake data generation completed');
  }

  Future<void> resetDatabase({void Function(String)? onLog}) async {
    onLog?.call('Resetting database: deleting collections');
    final collections = [
      'matches',
      'teams',
      'players',
      'tournaments',
      'standings'
    ];

    for (final col in collections) {
      onLog?.call('Clearing collection $col');
      final snapshot = await firestore.collection(col).get();
      var batch = firestore.batch();
      var opCount = 0;
      for (final doc in snapshot.docs) {
        // if matches, delete subcollection events first
        if (col == 'matches') {
          final eventsSnap = await doc.reference.collection('events').get();
          for (final ev in eventsSnap.docs) {
            batch.delete(ev.reference);
            opCount++;
            if (opCount >= _batchLimit) {
              await _commitBatchWithRetry(batch, onLog: onLog);
              batch = firestore.batch();
              opCount = 0;
            }
          }
        }

        batch.delete(doc.reference);
        opCount++;
        if (opCount >= _batchLimit) {
          await _commitBatchWithRetry(batch, onLog: onLog);
          batch = firestore.batch();
          opCount = 0;
        }
      }
      if (opCount > 0) await _commitBatchWithRetry(batch, onLog: onLog);
    }

    onLog?.call('Reset completed');
  }

  Future<void> reseed({void Function(String)? onLog}) async {
    onLog?.call('Reseeding: resetting then generating');
    await resetDatabase(onLog: onLog);
    await generateFakeData(onLog: onLog);
  }

  // Helpers
  Future<void> _writeIfNotExists(List<Map<String, dynamic>> items,
      {String? collectionName, void Function(String)? onLog}) async {
    if (items.isEmpty) return;
    // items expected to have keys: id, ref, data OR id and data and optional ref
    var batch = firestore.batch();
    var opCount = 0;

    for (final item in items) {
      final ref = item['ref'] as DocumentReference? ??
          (collectionName != null
              ? firestore.collection(collectionName).doc(item['id'])
              : null);
      if (ref == null) continue;

      final doc = await ref.get();
      if (doc.exists) {
        onLog?.call('Skipping existing: ${ref.path}');
        continue;
      }

      batch.set(ref, Map<String, dynamic>.from(item['data']));
      opCount++;

      if (opCount >= _batchLimit) {
        await _commitBatchWithRetry(batch, onLog: onLog);
        batch = firestore.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) await _commitBatchWithRetry(batch, onLog: onLog);
  }

  Future<void> _writeMatchesWithEvents(List<Map<String, dynamic>> matches,
      {void Function(String)? onLog}) async {
    if (matches.isEmpty) return;
    var batch = firestore.batch();
    var opCount = 0;

    for (final m in matches) {
      final ref = m['ref'] as DocumentReference;
      final doc = await ref.get();
      if (!doc.exists) {
        batch.set(ref, Map<String, dynamic>.from(m['data']));
        opCount++;
      } else {
        onLog?.call('Skipping existing match ${ref.id}');
      }

      // events
      final events = m['events'] as List<Map<String, dynamic>>;
      for (final ev in events) {
        final evRef = ref.collection('events').doc();
        final evDoc = await evRef.get();
        if (!evDoc.exists) {
          batch.set(evRef, Map<String, dynamic>.from(ev));
          opCount++;
        }

        if (opCount >= _batchLimit) {
          await _commitBatchWithRetry(batch, onLog: onLog);
          batch = firestore.batch();
          opCount = 0;
        }
      }
    }

    if (opCount > 0) await _commitBatchWithRetry(batch, onLog: onLog);
  }

  Future<void> _updateTeamCounts(
      List<Map<String, dynamic>> teams, List<Map<String, dynamic>> players,
      {void Function(String)? onLog}) async {
    final counts = <String, int>{};
    for (final p in players) {
      final teamId = p['data']['teamId'] as String? ?? '';
      if (teamId.isEmpty) continue;
      counts[teamId] = (counts[teamId] ?? 0) + 1;
    }

    var batch = firestore.batch();
    var opCount = 0;
    for (final t in teams) {
      final id = t['id'] as String;
      final ref = t['ref'] as DocumentReference;
      final newCount = counts[id] ?? 0;
      batch.update(ref, {'totalPlayers': newCount});
      opCount++;
      if (opCount >= _batchLimit) {
        await _commitBatchWithRetry(batch, onLog: onLog);
        batch = firestore.batch();
        opCount = 0;
      }
    }
    if (opCount > 0) await _commitBatchWithRetry(batch, onLog: onLog);
  }

  Future<void> _commitBatchWithRetry(WriteBatch batch,
      {void Function(String)? onLog, int maxRetries = 3}) async {
    var attempt = 0;
    while (true) {
      try {
        attempt++;
        await batch.commit();
        onLog?.call('Batch commit successful (attempt $attempt)');
        return;
      } catch (e) {
        onLog?.call('Batch commit failed (attempt $attempt): $e');
        if (attempt >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  List<Map<String, dynamic>> _computeStandings(
      List<Map<String, dynamic>> teams, List<Map<String, dynamic>> matches) {
    final stats = <String, Map<String, int>>{};
    for (final t in teams) {
      stats[t['id']] = {
        'points': 0,
        'wins': 0,
        'draws': 0,
        'losses': 0,
        'goalsFor': 0,
        'goalsAgainst': 0,
      };
    }

    for (final m in matches) {
      final data = m['data'] as Map<String, dynamic>;
      if (data['status'] != 'finished') continue;
      final home = data['homeTeamId'] as String;
      final away = data['awayTeamId'] as String;
      final score = data['score'] as Map<String, dynamic>;
      final homeGoals = score['home'] as int? ?? 0;
      final awayGoals = score['away'] as int? ?? 0;

      stats[home]!['goalsFor'] = (stats[home]!['goalsFor'] ?? 0) + homeGoals;
      stats[home]!['goalsAgainst'] =
          (stats[home]!['goalsAgainst'] ?? 0) + awayGoals;
      stats[away]!['goalsFor'] = (stats[away]!['goalsFor'] ?? 0) + awayGoals;
      stats[away]!['goalsAgainst'] =
          (stats[away]!['goalsAgainst'] ?? 0) + homeGoals;

      if (homeGoals > awayGoals) {
        stats[home]!['wins'] = (stats[home]!['wins'] ?? 0) + 1;
        stats[away]!['losses'] = (stats[away]!['losses'] ?? 0) + 1;
        stats[home]!['points'] = (stats[home]!['points'] ?? 0) + 3;
      } else if (homeGoals < awayGoals) {
        stats[away]!['wins'] = (stats[away]!['wins'] ?? 0) + 1;
        stats[home]!['losses'] = (stats[home]!['losses'] ?? 0) + 1;
        stats[away]!['points'] = (stats[away]!['points'] ?? 0) + 3;
      } else {
        stats[home]!['draws'] = (stats[home]!['draws'] ?? 0) + 1;
        stats[away]!['draws'] = (stats[away]!['draws'] ?? 0) + 1;
        stats[home]!['points'] = (stats[home]!['points'] ?? 0) + 1;
        stats[away]!['points'] = (stats[away]!['points'] ?? 0) + 1;
      }
    }

    final List<Map<String, dynamic>> standings = [];
    for (final t in teams) {
      final s = stats[t['id']]!;
      final gd = (s['goalsFor'] ?? 0) - (s['goalsAgainst'] ?? 0);
      standings.add({
        'id': t['id'],
        'ref': firestore.collection('standings').doc(t['id']),
        'data': {
          'teamId': t['id'],
          'teamName': t['data']['name'],
          'points': s['points'] ?? 0,
          'wins': s['wins'] ?? 0,
          'draws': s['draws'] ?? 0,
          'losses': s['losses'] ?? 0,
          'goalDifference': gd,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });
    }

    return standings;
  }

  Future<List<Map<String, dynamic>>> _generateTournaments() async {
    final collection = firestore.collection('tournaments');
    final names = [
      'Premier Friendly Cup',
      'Autumn Invitational',
      'City League'
    ];
    final List<Map<String, dynamic>> list = [];
    for (final n in names) {
      final ref = collection.doc();
      list.add({
        'id': ref.id,
        'ref': ref,
        'data': {
          'name': n,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });
    }
    return list;
  }
}
