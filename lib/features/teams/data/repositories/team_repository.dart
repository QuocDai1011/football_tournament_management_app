import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/team_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

abstract class TeamRepository {
  Stream<List<TeamModel>> watchTeams();
  Future<Either<Failure, TeamModel>> getTeam(String id);
  Future<Either<Failure, String>> createTeam(TeamModel team);
  Future<Either<Failure, void>> updateTeam(TeamModel team);
  Future<Either<Failure, void>> deleteTeam(String id);
}

class TeamRepositoryImpl implements TeamRepository {
  final FirestoreService _firestore;

  TeamRepositoryImpl(this._firestore);

  @override
  Stream<List<TeamModel>> watchTeams() {
    return _firestore
        .collectionStream(
          FirestoreCollections.teams,
          orderBy: [const QueryOrder('name')],
        )
        .map((snap) => snap.docs
            .map((d) => TeamModel.fromJson(d.data(), d.id))
            .toList());
  }

  @override
  Future<Either<Failure, TeamModel>> getTeam(String id) async {
    try {
      final doc = await _firestore.getDocument(FirestoreCollections.teams, id);
      if (!doc.exists) return Left(DatabaseFailure.notFound('Team'));
      return Right(TeamModel.fromJson(doc.data()!, doc.id));
    } catch (e) {
      return Left(UnexpectedFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> createTeam(TeamModel team) async {
    try {
      final ref = await _firestore.addDocument(
        FirestoreCollections.teams,
        team.toJson(),
      );
      return Right(ref.id);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTeam(TeamModel team) async {
    try {
      await _firestore.updateDocument(
        FirestoreCollections.teams,
        team.id,
        team.toJson(),
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTeam(String id) async {
    try {
      await _firestore.deleteDocument(FirestoreCollections.teams, id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}

// Providers
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepositoryImpl(ref.read(firestoreServiceProvider));
});

final teamsStreamProvider = StreamProvider<List<TeamModel>>((ref) {
  return ref.watch(teamRepositoryProvider).watchTeams();
});

final teamDetailProvider =
    FutureProvider.family<TeamModel?, String>((ref, id) async {
  final result = await ref.read(teamRepositoryProvider).getTeam(id);
  return result.getOrNull();
});

class TeamNotifier extends StateNotifier<AsyncValue<void>> {
  final TeamRepository _repo;
  TeamNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<Either<Failure, String>> create(TeamModel team) async {
    state = const AsyncValue.loading();
    final result = await _repo.createTeam(team);
    state = const AsyncValue.data(null);
    return result;
  }

  Future<Either<Failure, void>> update(TeamModel team) async {
    state = const AsyncValue.loading();
    final result = await _repo.updateTeam(team);
    state = const AsyncValue.data(null);
    return result;
  }

  Future<Either<Failure, void>> delete(String id) async {
    state = const AsyncValue.loading();
    final result = await _repo.deleteTeam(id);
    state = const AsyncValue.data(null);
    return result;
  }
}

final teamNotifierProvider =
    StateNotifierProvider<TeamNotifier, AsyncValue<void>>((ref) {
  return TeamNotifier(ref.read(teamRepositoryProvider));
});
