import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/season_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

abstract class SeasonRepository {
  Stream<List<SeasonModel>> watchSeasons({String? tournamentId});
  Future<Either<Failure, SeasonModel>> getSeason(String id);
  Future<Either<Failure, String>> createSeason(SeasonModel season);
  Future<Either<Failure, void>> updateSeason(SeasonModel season);
  Future<Either<Failure, void>> deleteSeason(String id);
}

class SeasonRepositoryImpl implements SeasonRepository {
  final FirestoreService _firestore;
  SeasonRepositoryImpl(this._firestore);

  @override
  Stream<List<SeasonModel>> watchSeasons({String? tournamentId}) {
    return _firestore.collectionStream(
      FirestoreCollections.seasons,
      filters: tournamentId != null
          ? [QueryFilter.equalTo('tournamentId', tournamentId)]
          : null,
      orderBy: [const QueryOrder('startDate', descending: true)],
    ).map((snap) =>
        snap.docs.map((d) => SeasonModel.fromJson(d.data(), d.id)).toList());
  }

  @override
  Future<Either<Failure, SeasonModel>> getSeason(String id) async {
    try {
      final doc =
          await _firestore.getDocument(FirestoreCollections.seasons, id);
      if (!doc.exists) return Left(DatabaseFailure.notFound('Season'));
      return Right(SeasonModel.fromJson(doc.data()!, doc.id));
    } catch (e) {
      return Left(UnexpectedFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> createSeason(SeasonModel season) async {
    try {
      final ref = await _firestore.addDocument(
          FirestoreCollections.seasons, season.toJson());
      return Right(ref.id);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSeason(SeasonModel season) async {
    try {
      await _firestore.updateDocument(
          FirestoreCollections.seasons, season.id, season.toJson());
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSeason(String id) async {
    try {
      await _firestore.deleteDocument(FirestoreCollections.seasons, id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}

// Providers
final seasonRepositoryProvider = Provider<SeasonRepository>((ref) {
  return SeasonRepositoryImpl(ref.read(firestoreServiceProvider));
});

final seasonsStreamProvider =
    StreamProvider.family<List<SeasonModel>, String?>((ref, tournamentId) {
  return ref
      .watch(seasonRepositoryProvider)
      .watchSeasons(tournamentId: tournamentId);
});

final allSeasonsStreamProvider = StreamProvider<List<SeasonModel>>((ref) {
  return ref.watch(seasonRepositoryProvider).watchSeasons();
});

final seasonDetailProvider =
    FutureProvider.family<SeasonModel?, String>((ref, id) async {
  final result = await ref.read(seasonRepositoryProvider).getSeason(id);
  return result.getOrNull();
});

class SeasonNotifier extends StateNotifier<AsyncValue<void>> {
  final SeasonRepository _repo;
  SeasonNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<Either<Failure, String>> create(SeasonModel season) async {
    state = const AsyncValue.loading();
    final result = await _repo.createSeason(season);
    state = const AsyncValue.data(null);
    return result;
  }

  Future<Either<Failure, void>> update(SeasonModel season) async {
    state = const AsyncValue.loading();
    final result = await _repo.updateSeason(season);
    state = const AsyncValue.data(null);
    return result;
  }

  Future<Either<Failure, void>> delete(String id) async {
    state = const AsyncValue.loading();
    final result = await _repo.deleteSeason(id);
    state = const AsyncValue.data(null);
    return result;
  }
}

final seasonNotifierProvider =
    StateNotifierProvider<SeasonNotifier, AsyncValue<void>>((ref) {
  return SeasonNotifier(ref.read(seasonRepositoryProvider));
});
