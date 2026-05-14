import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Type alias for use-case results
typedef Result<T> = Future<Either<Failure, T>>;

/// Synchronous result
typedef SyncResult<T> = Either<Failure, T>;

/// Extension methods for working with Either results
extension EitherExtensions<L, R> on Either<L, R> {
  /// Returns the right value or null
  R? getOrNull() => fold((_) => null, (r) => r);

  /// Returns true if this is a Right (success)
  bool get isSuccess => isRight();

  /// Returns true if this is a Left (failure)
  bool get isFailure => isLeft();

  /// Maps the right value, keeping the left
  Either<L, T> flatMap<T>(Either<L, T> Function(R r) f) => bind(f);
}

/// Helper to safely execute async operations and convert exceptions to failures
Future<Either<Failure, T>> safeCall<T>(
  Future<T> Function() call, {
  Failure Function(Object e)? onError,
}) async {
  try {
    final result = await call();
    return Right(result);
  } catch (e) {
    if (onError != null) {
      return Left(onError(e));
    }
    return Left(UnexpectedFailure.fromException(e));
  }
}
