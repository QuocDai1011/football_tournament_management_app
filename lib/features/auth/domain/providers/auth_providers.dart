import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/admin_model.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/services/firestore_service.dart'
    show FirestoreCollections, FirestoreService;

abstract class AuthRepository {
  Future<Either<Failure, AdminModel>> signIn(String email, String password);
  Future<Either<Failure, void>> signOut();
  Stream<User?> get authStateChanges;
  Future<Either<Failure, AdminModel>> getCurrentAdmin();
}

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirestoreService _firestore;
  final _log = Logger();

  AuthRepositoryImpl(this._auth, this._firestore);

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<Either<Failure, AdminModel>> signIn(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return Left(AuthFailure.invalidCredentials());
      }

      // Verify admin exists in Firestore
      final doc = await _firestore.getDocument(
        FirestoreCollections.admins,
        user.uid,
      );

      if (!doc.exists) {
        // Sign out silently — không để Firebase emit sign-out event
        // gây conflict với router redirect
        await _auth.signOut();
        return Left(AuthFailure.unauthorized());
      }

      final admin = AdminModel.fromJson(doc.data()!, doc.id);

      // Update last login — luôn dùng Timestamp
      await _firestore.updateDocument(
        FirestoreCollections.admins,
        user.uid,
        {'lastLoginAt': Timestamp.fromDate(DateTime.now())},
      );

      return Right(admin);
    } on FirebaseAuthException catch (e) {
      _log.e('SignIn FirebaseAuthException', error: e);
      return Left(_mapFirebaseError(e));
    } catch (e) {
      _log.e('SignIn unexpected error', error: e);
      return Left(UnexpectedFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, AdminModel>> getCurrentAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return Left(AuthFailure.sessionExpired());

      final doc = await _firestore.getDocument(
        FirestoreCollections.admins,
        user.uid,
      );

      if (!doc.exists) return Left(AuthFailure.unauthorized());
      return Right(AdminModel.fromJson(doc.data()!, doc.id));
    } catch (e) {
      return Left(UnexpectedFailure.fromException(e));
    }
  }

  AuthFailure _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthFailure.userNotFound();
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailure.invalidCredentials();
      case 'user-disabled':
        return const AuthFailure(
            message: 'Account disabled.', code: 'user-disabled');
      case 'too-many-requests':
        return const AuthFailure(
            message: 'Too many attempts. Try again later.',
            code: 'too-many-requests');
      default:
        return AuthFailure(
            message: e.message ?? 'Authentication failed.', code: e.code);
    }
  }
}

// Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(firebaseAuthProvider),
    ref.read(firestoreServiceProvider),
  );
});

/// Auth state stream provider — tracks Firebase auth state.
/// Dùng authStateChanges() thay vì idTokenChanges() để tránh
/// emit thêm events không cần thiết.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Current admin data provider
final currentAdminProvider = FutureProvider<AdminModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return null;
  final result = await ref.read(authRepositoryProvider).getCurrentAdmin();
  return result.getOrNull();
});
