import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/player_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

abstract class PlayerRepository {
  Stream<List<PlayerModel>> watchPlayers({String? teamId});
  Future<Either<Failure, PlayerModel>> getPlayer(String id);
  Future<Either<Failure, String>> createPlayer(PlayerModel player);
  Future<Either<Failure, void>> updatePlayer(PlayerModel player);
  Future<Either<Failure, void>> deletePlayer(String id);
}

class PlayerRepositoryImpl implements PlayerRepository {
  final FirestoreService _firestore;
  PlayerRepositoryImpl(this._firestore);

  @override
  Stream<List<PlayerModel>> watchPlayers({String? teamId}) {
    return _firestore
        .collectionStream(
          FirestoreCollections.players,
          filters: teamId != null
              ? [QueryFilter.equalTo('teamId', teamId)]
              : null,
          orderBy: [const QueryOrder('name')],
        )
        .map((snap) => snap.docs
            .map((d) => PlayerModel.fromJson(d.data(), d.id))
            .toList());
  }

  @override
  Future<Either<Failure, PlayerModel>> getPlayer(String id) async {
    try {
      final doc =
          await _firestore.getDocument(FirestoreCollections.players, id);
      if (!doc.exists) return Left(DatabaseFailure.notFound('Player'));
      return Right(PlayerModel.fromJson(doc.data()!, doc.id));
    } catch (e) {
      return Left(UnexpectedFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> createPlayer(PlayerModel player) async {
    try {
      final ref = await _firestore.addDocument(
          FirestoreCollections.players, player.toJson());
      return Right(ref.id);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePlayer(PlayerModel player) async {
    try {
      await _firestore.updateDocument(
          FirestoreCollections.players, player.id, player.toJson());
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlayer(String id) async {
    try {
      await _firestore.deleteDocument(FirestoreCollections.players, id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}

// Providers
final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepositoryImpl(ref.read(firestoreServiceProvider));
});

final playersStreamProvider = StreamProvider<List<PlayerModel>>((ref) {
  return ref.watch(playerRepositoryProvider).watchPlayers();
});

final playersByTeamProvider =
    StreamProvider.family<List<PlayerModel>, String>((ref, teamId) {
  return ref.watch(playerRepositoryProvider).watchPlayers(teamId: teamId);
});

final playerDetailProvider =
    FutureProvider.family<PlayerModel?, String>((ref, id) async {
  final result = await ref.read(playerRepositoryProvider).getPlayer(id);
  return result.getOrNull();
});

class PlayerNotifier extends StateNotifier<AsyncValue<void>> {
  final PlayerRepository _repo;
  PlayerNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<Either<Failure, String>> create(PlayerModel player) async {
    state = const AsyncValue.loading();
    final result = await _repo.createPlayer(player);
    state = const AsyncValue.data(null);
    return result;
  }

  Future<Either<Failure, void>> update(PlayerModel player) async {
    state = const AsyncValue.loading();
    final result = await _repo.updatePlayer(player);
    state = const AsyncValue.data(null);
    return result;
  }

  Future<Either<Failure, void>> delete(String id) async {
    state = const AsyncValue.loading();
    final result = await _repo.deletePlayer(id);
    state = const AsyncValue.data(null);
    return result;
  }
}

final playerNotifierProvider =
    StateNotifierProvider<PlayerNotifier, AsyncValue<void>>((ref) {
  return PlayerNotifier(ref.read(playerRepositoryProvider));
});
