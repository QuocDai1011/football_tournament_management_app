import 'package:equatable/equatable.dart';

/// Base failure class for all domain-level errors
sealed class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Firebase-related authentication failures
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});

  factory AuthFailure.invalidCredentials() =>
      const AuthFailure(message: 'Invalid email or password.', code: 'invalid-credentials');

  factory AuthFailure.userNotFound() =>
      const AuthFailure(message: 'User not found.', code: 'user-not-found');

  factory AuthFailure.sessionExpired() =>
      const AuthFailure(message: 'Session expired. Please log in again.', code: 'session-expired');

  factory AuthFailure.unauthorized() =>
      const AuthFailure(message: 'You are not authorized to perform this action.', code: 'unauthorized');
}

/// Firestore / database failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code});

  factory DatabaseFailure.notFound(String entity) =>
      DatabaseFailure(message: '$entity not found.', code: 'not-found');

  factory DatabaseFailure.alreadyExists(String entity) =>
      DatabaseFailure(message: '$entity already exists.', code: 'already-exists');

  factory DatabaseFailure.permissionDenied() =>
      const DatabaseFailure(message: 'Permission denied.', code: 'permission-denied');
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});

  factory NetworkFailure.noConnection() =>
      const NetworkFailure(message: 'No internet connection.', code: 'no-connection');

  factory NetworkFailure.timeout() =>
      const NetworkFailure(message: 'Request timed out. Please try again.', code: 'timeout');
}

/// Storage (Cloudinary) failures
class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});

  factory StorageFailure.uploadFailed() =>
      const StorageFailure(message: 'Image upload failed.', code: 'upload-failed');

  factory StorageFailure.deleteFailed() =>
      const StorageFailure(message: 'Image deletion failed.', code: 'delete-failed');
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});

  factory ValidationFailure.invalidInput(String field) =>
      ValidationFailure(message: 'Invalid input for $field.', code: 'invalid-input');

  factory ValidationFailure.required(String field) =>
      ValidationFailure(message: '$field is required.', code: 'required');
}

/// Unknown / unexpected failures
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});

  factory UnexpectedFailure.fromException(Object e) =>
      UnexpectedFailure(message: e.toString(), code: 'unexpected');
}
