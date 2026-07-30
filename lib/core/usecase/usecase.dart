import 'package:equatable/equatable.dart';

import '../error/failure.dart';
import '../utils/either.dart';

/// Base contract for all use cases in the domain layer.
///
/// A use case is a single, focused piece of business logic. It accepts
/// [Params] (or [NoParams]) and returns a result wrapped in [Either] so
/// failures are explicit and recoverable.
abstract class UseCase<T, Params> {
  const UseCase();

  Future<Either<Failure, T>> call(Params params);
}

/// Use case variant that returns a stream of results (e.g. watching a
/// database table for live updates).
abstract class StreamUseCase<T, Params> {
  const StreamUseCase();

  Stream<Either<Failure, T>> call(Params params);
}

/// Common supertype for use case parameter objects. Marked [Equatable]
/// so they can be safely compared by value.
abstract class Params extends Equatable {
  const Params();

  @override
  List<Object?> get props => const [];
}