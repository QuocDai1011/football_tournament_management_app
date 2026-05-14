import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/tournament_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

/// Tournament repository interface
abstract class TournamentRepository {
  Stream<List<TournamentModel>> watchTournaments();
  Future<Either<Failure, TournamentModel>> getTournament(String id);
  Future<Either<Failure, String>> createTournament(TournamentModel tournament);
  Future<Either<Failure, void>> updateTournament(TournamentModel tournament);
  Future<Either<Failure, void>> deleteTournament(String id);
  Future<Either<Failure, List<TournamentModel>>> searchTournaments(
      String query);
}

class TournamentRepositoryImpl implements TournamentRepository {
  final FirestoreService _firestore;

  TournamentRepositoryImpl(this._firestore);

  @override
  Stream<List<TournamentModel>> watchTournaments() {
    return _firestore.collectionStream(
      FirestoreCollections.tournaments,
      orderBy: [const QueryOrder('createdAt', descending: true)],
    ).map((snapshot) => snapshot.docs
        .map((doc) => TournamentModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  @override
  Future<Either<Failure, TournamentModel>> getTournament(String id) async {
    try {
      final doc = await _firestore.getDocument(
        FirestoreCollections.tournaments,
        id,
      );
      if (!doc.exists) return Left(DatabaseFailure.notFound('Tournament'));
      return Right(TournamentModel.fromJson(doc.data()!, doc.id));
    } catch (e) {
      return Left(UnexpectedFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> createTournament(
      TournamentModel tournament) async {
    try {
      // toJson() đã dùng Timestamp — không override bằng String nữa
      final ref = await _firestore.addDocument(
        FirestoreCollections.tournaments,
        tournament.toJson(),
      );
      return Right(ref.id);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTournament(
      TournamentModel tournament) async {
    try {
      // toJson() đã dùng Timestamp — không override bằng String nữa
      await _firestore.updateDocument(
        FirestoreCollections.tournaments,
        tournament.id,
        tournament.toJson(),
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTournament(String id) async {
    try {
      await _firestore.deleteDocument(FirestoreCollections.tournaments, id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TournamentModel>>> searchTournaments(
      String query) async {
    try {
      // Firestore doesn't support full-text search natively
      // Using client-side filtering here; for production use Algolia or Cloud Functions
      final snapshot = await _firestore.getCollection(
        FirestoreCollections.tournaments,
      );
      final all = snapshot.docs
          .map((doc) => TournamentModel.fromJson(doc.data(), doc.id))
          .toList();
      final filtered = all
          .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      return Right(filtered);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}

// ---- Riverpod Providers ----

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepositoryImpl(ref.read(firestoreServiceProvider));
});

final tournamentsStreamProvider = StreamProvider<List<TournamentModel>>((ref) {
  return ref.watch(tournamentRepositoryProvider).watchTournaments();
});

final tournamentDetailProvider =
    FutureProvider.family<TournamentModel?, String>((ref, id) async {
  final result = await ref.read(tournamentRepositoryProvider).getTournament(id);
  return result.getOrNull();
});

/// Notifier for tournament CRUD actions
class TournamentNotifier extends StateNotifier<AsyncValue<void>> {
  final TournamentRepository _repository;

  TournamentNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<Either<Failure, String>> create(TournamentModel tournament) async {
    state = const AsyncValue.loading();
    final result = await _repository.createTournament(tournament);
    state = const AsyncValue.data(null);
    return result;
  }

  Future<Either<Failure, void>> update(TournamentModel tournament) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateTournament(tournament);
    state = const AsyncValue.data(null);
    return result;
  }

  Future<Either<Failure, void>> delete(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteTournament(id);
    state = const AsyncValue.data(null);
    return result;
  }
}

final tournamentNotifierProvider =
    StateNotifierProvider<TournamentNotifier, AsyncValue<void>>((ref) {
  return TournamentNotifier(ref.read(tournamentRepositoryProvider));
});
