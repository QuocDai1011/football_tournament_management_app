import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/registration_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

abstract class RegistrationRepository {
  Stream<List<RegistrationModel>> watchRegistrations({
    String? tournamentId,
    String? seasonId,
    String? teamId,
  });
  Future<Either<Failure, RegistrationModel>> getRegistration(String id);
  Future<Either<Failure, String>> createRegistration(
      RegistrationModel registration);
  Future<Either<Failure, void>> updateRegistration(
      RegistrationModel registration);
  Future<Either<Failure, void>> deleteRegistration(String id);
  Future<Either<Failure, void>> approveRegistration(String id, String? group);
  Future<Either<Failure, void>> rejectRegistration(String id, String reason);
}

class RegistrationRepositoryImpl implements RegistrationRepository {
  final FirestoreService _firestore;
  RegistrationRepositoryImpl(this._firestore);

  @override
  Stream<List<RegistrationModel>> watchRegistrations({
    String? tournamentId,
    String? seasonId,
    String? teamId,
  }) {
    final filters = <QueryFilter>[];
    if (tournamentId != null) {
      filters.add(QueryFilter.equalTo('tournamentId', tournamentId));
    }
    if (seasonId != null) {
      filters.add(QueryFilter.equalTo('seasonId', seasonId));
    }
    if (teamId != null) {
      filters.add(QueryFilter.equalTo('teamId', teamId));
    }

    return _firestore.collectionStream(
      FirestoreCollections.registrations,
      filters: filters.isEmpty ? null : filters,
    ).map((snap) {
      final list = snap.docs
          .map((d) => RegistrationModel.fromJson(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return list;
    });
  }

  @override
  Future<Either<Failure, RegistrationModel>> getRegistration(String id) async {
    try {
      final doc =
          await _firestore.getDocument(FirestoreCollections.registrations, id);
      if (!doc.exists) return Left(DatabaseFailure.notFound('Registration'));
      return Right(RegistrationModel.fromJson(doc.data()!, doc.id));
    } catch (e) {
      return Left(UnexpectedFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> createRegistration(
      RegistrationModel registration) async {
    try {
      // Check for duplicate registration
      final existingSnap = await _firestore.getCollection(
        FirestoreCollections.registrations,
        filters: [
          QueryFilter.equalTo('tournamentId', registration.tournamentId),
        ],
      );

      final isDuplicate = existingSnap.docs.any((doc) {
        final data = doc.data();
        return data['teamId'] == registration.teamId;
      });

      if (isDuplicate) {
        return Left(DatabaseFailure.alreadyExists('Registration'));
      }

      final ref = await _firestore.addDocument(
          FirestoreCollections.registrations, registration.toJson());
      return Right(ref.id);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateRegistration(
      RegistrationModel registration) async {
    try {
      await _firestore.updateDocument(FirestoreCollections.registrations,
          registration.id, registration.toJson());
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRegistration(String id) async {
    try {
      await _firestore.deleteDocument(FirestoreCollections.registrations, id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveRegistration(
      String id, String? group) async {
    try {
      await _firestore.updateDocument(
        FirestoreCollections.registrations,
        id,
        {
          'status': RegistrationStatus.approved.value,
          'approvedAt': Timestamp.fromDate(DateTime.now()), // Dùng Timestamp
          if (group != null) 'group': group,
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectRegistration(
      String id, String reason) async {
    try {
      await _firestore.updateDocument(
        FirestoreCollections.registrations,
        id,
        {
          'status': RegistrationStatus.rejected.value,
          'notes': reason,
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}

// Providers
final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  return RegistrationRepositoryImpl(ref.read(firestoreServiceProvider));
});

final registrationsStreamProvider = StreamProvider.autoDispose.family<
    List<RegistrationModel>, ({String? tournamentId, String? seasonId})>(
  (ref, params) {
    return ref.watch(registrationRepositoryProvider).watchRegistrations(
          tournamentId: params.tournamentId,
          seasonId: params.seasonId,
        );
  },
);

final registrationDetailProvider =
    FutureProvider.family<RegistrationModel?, String>((ref, id) async {
  final result =
      await ref.read(registrationRepositoryProvider).getRegistration(id);
  return result.getOrNull();
});

class RegistrationNotifier extends StateNotifier<AsyncValue<void>> {
  final RegistrationRepository _repo;
  RegistrationNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<Either<Failure, String>> create(RegistrationModel registration) async {
    state = const AsyncValue.loading();
    final result = await _repo.createRegistration(registration);
    state = const AsyncValue.data(null);
    return result;
  }

  Future<Either<Failure, void>> approve(String id, String? group) async {
    state = const AsyncValue.loading();
    final result = await _repo.approveRegistration(id, group);
    state = const AsyncValue.data(null);
    return result;
  }

  Future<Either<Failure, void>> reject(String id, String reason) async {
    state = const AsyncValue.loading();
    final result = await _repo.rejectRegistration(id, reason);
    state = const AsyncValue.data(null);
    return result;
  }

  Future<Either<Failure, void>> delete(String id) async {
    state = const AsyncValue.loading();
    final result = await _repo.deleteRegistration(id);
    state = const AsyncValue.data(null);
    return result;
  }
}

final registrationNotifierProvider =
    StateNotifierProvider<RegistrationNotifier, AsyncValue<void>>((ref) {
  return RegistrationNotifier(ref.read(registrationRepositoryProvider));
});
