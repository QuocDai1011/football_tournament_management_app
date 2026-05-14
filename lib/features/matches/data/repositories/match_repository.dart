import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/match_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/algorithms/fixture_generator.dart';

abstract class MatchRepository {
  Stream<List<MatchModel>> watchMatches({String? tournamentId});
  Stream<List<MatchEvent>> watchMatchEvents(String matchId);
  Future<Either<Failure, MatchModel>> getMatch(String id);
  Future<Either<Failure, String>> createMatch(MatchModel match);
  Future<Either<Failure, void>> updateMatch(MatchModel match);
  Future<Either<Failure, void>> deleteMatch(String id);
  Future<Either<Failure, String>> addMatchEvent(MatchEvent event);
  Future<Either<Failure, void>> deleteMatchEvent(
      String matchId, String eventId);
  Future<Either<Failure, void>> startMatch(String matchId);
  Future<Either<Failure, void>> finishMatch(
      String matchId, int homeScore, int awayScore);
  Future<Either<Failure, List<String>>> generateFixtures(
    String tournamentId,
    List<String> teamIds, {
    String? group,
    MatchType type,
  });
}

class MatchRepositoryImpl implements MatchRepository {
  final FirestoreService _firestore;
  MatchRepositoryImpl(this._firestore);

  @override
  Stream<List<MatchModel>> watchMatches({String? tournamentId}) {
    return _firestore
        .collectionStream(
          FirestoreCollections.matches,
          filters: tournamentId != null
              ? [QueryFilter.equalTo('tournamentId', tournamentId)]
              : null,
        )
        .map((snap) {
          final list = snap.docs
              .map((d) => MatchModel.fromJson(d.data(), d.id))
              .toList();
          list.sort((a, b) {
            if (a.scheduledAt == null && b.scheduledAt == null) return 0;
            if (a.scheduledAt == null) return 1;
            if (b.scheduledAt == null) return -1;
            return b.scheduledAt!.compareTo(a.scheduledAt!);
          });
          return list;
        });
  }

  @override
  Stream<List<MatchEvent>> watchMatchEvents(String matchId) {
    return _firestore
        .subcollectionStream(
          FirestoreCollections.matches,
          matchId,
          FirestoreCollections.matchEvents,
          orderBy: [const QueryOrder('minute')],
        )
        .map((snap) => snap.docs
            .map((d) => MatchEvent.fromJson(d.data(), d.id))
            .toList());
  }

  @override
  Future<Either<Failure, MatchModel>> getMatch(String id) async {
    try {
      final doc =
          await _firestore.getDocument(FirestoreCollections.matches, id);
      if (!doc.exists) return Left(DatabaseFailure.notFound('Match'));
      return Right(MatchModel.fromJson(doc.data()!, doc.id));
    } catch (e) {
      return Left(UnexpectedFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> createMatch(MatchModel match) async {
    try {
      final ref = await _firestore.addDocument(
          FirestoreCollections.matches, match.toJson());
      return Right(ref.id);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMatch(MatchModel match) async {
    try {
      await _firestore.updateDocument(
          FirestoreCollections.matches, match.id, match.toJson());
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMatch(String id) async {
    try {
      await _firestore.deleteDocument(FirestoreCollections.matches, id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> addMatchEvent(MatchEvent event) async {
    try {
      final ref = await _firestore.addSubdocument(
        FirestoreCollections.matches,
        event.matchId,
        FirestoreCollections.matchEvents,
        event.toJson(),
      );
      // Update score if goal event
      if (event.type == MatchEventType.goal ||
          event.type == MatchEventType.penalty) {
        await _updateScore(event.matchId);
      }
      return Right(ref.id);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  Future<void> _updateScore(String matchId) async {
    final eventsSnap = await _firestore.getCollection(
      '${FirestoreCollections.matches}/$matchId/${FirestoreCollections.matchEvents}',
    );
    int homeScore = 0;
    int awayScore = 0;
    for (final doc in eventsSnap.docs) {
      final data = doc.data();
      final type = MatchEventTypeExtension.fromString(data['type'] as String? ?? '');
      if (type == MatchEventType.goal || type == MatchEventType.penalty || type == MatchEventType.ownGoal) {
        final isHome = data['isHomeTeam'] as bool? ?? true;
        if (type == MatchEventType.ownGoal) {
          if (isHome) awayScore++; else homeScore++;
        } else {
          if (isHome) homeScore++; else awayScore++;
        }
      }
    }
    await _firestore.updateDocument(FirestoreCollections.matches, matchId, {
      'homeScore': homeScore,
      'awayScore': awayScore,
    });
  }

  @override
  Future<Either<Failure, void>> deleteMatchEvent(
      String matchId, String eventId) async {
    try {
      await _firestore.deleteDocument(
        '${FirestoreCollections.matches}/$matchId/${FirestoreCollections.matchEvents}',
        eventId,
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startMatch(String matchId) async {
    try {
      await _firestore.updateDocument(FirestoreCollections.matches, matchId, {
        'status': MatchStatus.live.value,
        'minute': 0,
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> finishMatch(
      String matchId, int homeScore, int awayScore) async {
    try {
      final doc = await _firestore.getDocument(FirestoreCollections.matches, matchId);
      final match = MatchModel.fromJson(doc.data()!, doc.id);

      await _firestore.updateDocument(FirestoreCollections.matches, matchId, {
        'status': MatchStatus.finished.value,
        'homeScore': homeScore,
        'awayScore': awayScore,
      });

      if (match.status != MatchStatus.finished) {
        await _updateTeamStats(match.homeTeamId, homeScore, awayScore);
        await _updateTeamStats(match.awayTeamId, awayScore, homeScore);
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  Future<void> _updateTeamStats(String teamId, int goalsFor, int goalsAgainst) async {
    try {
      final doc = await _firestore.getDocument(FirestoreCollections.teams, teamId);
      if (!doc.exists) return;
      final data = doc.data()!;
      int wins = data['wins'] as int? ?? 0;
      int draws = data['draws'] as int? ?? 0;
      int losses = data['losses'] as int? ?? 0;
      int gf = data['goalsFor'] as int? ?? 0;
      int ga = data['goalsAgainst'] as int? ?? 0;

      if (goalsFor > goalsAgainst) wins++;
      else if (goalsFor == goalsAgainst) draws++;
      else losses++;

      await _firestore.updateDocument(FirestoreCollections.teams, teamId, {
        'wins': wins,
        'draws': draws,
        'losses': losses,
        'goalsFor': gf + goalsFor,
        'goalsAgainst': ga + goalsAgainst,
      });
    } catch (_) {}
  }

  @override
  Future<Either<Failure, List<String>>> generateFixtures(
    String tournamentId,
    List<String> teamIds, {
    String? group,
    MatchType type = MatchType.groupStage,
  }) async {
    try {
      final fixtures = FixtureGenerator.roundRobin(teamIds);
      final matchIds = <String>[];

      for (final fixture in fixtures) {
        final match = MatchModel(
          id: '',
          tournamentId: tournamentId,
          homeTeamId: fixture.$1,
          homeTeamName: '', // Will be populated by Cloud Function
          awayTeamId: fixture.$2,
          awayTeamName: '',
          status: MatchStatus.scheduled,
          type: type,
          group: group,
          round: fixture.$3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final ref = await _firestore.addDocument(
          FirestoreCollections.matches,
          match.toJson(),
        );
        matchIds.add(ref.id);
      }

      // Update tournament match count
      await _firestore.updateDocument(
        FirestoreCollections.tournaments,
        tournamentId,
        {'totalMatches': matchIds.length},
      );

      return Right(matchIds);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}

// Providers
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepositoryImpl(ref.read(firestoreServiceProvider));
});

final matchesStreamProvider =
    StreamProvider.family<List<MatchModel>, String?>((ref, tournamentId) {
  return ref.watch(matchRepositoryProvider).watchMatches(tournamentId: tournamentId);
});

final allMatchesStreamProvider = StreamProvider<List<MatchModel>>((ref) {
  return ref.watch(matchRepositoryProvider).watchMatches();
});

final matchEventsProvider =
    StreamProvider.family<List<MatchEvent>, String>((ref, matchId) {
  return ref.watch(matchRepositoryProvider).watchMatchEvents(matchId);
});

final matchDetailProvider =
    FutureProvider.family<MatchModel?, String>((ref, id) async {
  final result = await ref.read(matchRepositoryProvider).getMatch(id);
  return result.getOrNull();
});
