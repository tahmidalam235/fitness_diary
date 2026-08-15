import 'dart:async';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../../../session/data/datasources/session_local_datasource.dart';
import '../../domain/entities/body_part.dart';
import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/workout_local_datasource.dart';

/// Concrete implementation of [WorkoutRepository] backed by Firestore.
///
/// The data source mirrors writes to Firestore directly; the sync
/// service is used to re-emit join + master rows on top of the
/// data source's own upload so the cloud row carries the latest
/// state.
class WorkoutRepositoryImpl implements WorkoutRepository {
  const WorkoutRepositoryImpl({
    required this.dataSource,
    required this.sessionDataSource,
    this.sync,
  });

  final WorkoutLocalDataSource dataSource;
  final SessionLocalDataSource sessionDataSource;
  final SyncService? sync;

  @override
  Stream<Either<Failure, List<Workout>>> watchWorkoutsForSession(
    int sessionId,
  ) {
    // The data source accepts either a Firestore id or the int hash;
    // both are handled in `watchForSession`.
    return dataSource
        .watchForSession(sessionId.toString())
        .map<Either<Failure, List<Workout>>>((models) {
          final list = <Workout>[for (final m in models) m.toEntity()];
          return Right<Failure, List<Workout>>(list);
        })
        .handleError(
          (Object error) => Left<Failure, List<Workout>>(
            mapExceptionToFailure(
              error is AppException
                  ? error
                  : UnexpectedException(
                      'Failed to watch workouts',
                      cause: error,
                    ),
            ),
          ),
        );
  }

  @override
  Stream<Either<Failure, List<Workout>>> watchAllWorkouts() {
    return dataSource.workoutDao.watchAllWorkouts().map<
      Either<Failure, List<Workout>>
    >((models) {
      final list = <Workout>[for (final m in models) m.toEntity()];
      return Right<Failure, List<Workout>>(list);
    }).handleError(
      (Object error) => Left<Failure, List<Workout>>(
        mapExceptionToFailure(
          error is AppException
              ? error
              : UnexpectedException(
                  'Failed to watch all workouts',
                  cause: error,
                ),
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, Workout>> addWorkoutToSession({
    required int sessionId,
    required String exerciseName,
    required int defaultSets,
    required int defaultReps,
    int? defaultDurationSeconds,
    double? defaultWeight,
    String notes = '',
    BodyPart? targetedBodyPart,
  }) async {
    return _guard(() async {
      final sessionFid = await _resolveSessionFirestoreId(sessionId);
      final model = await dataSource.insert(
        sessionId: sessionFid,
        exerciseName: exerciseName,
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        defaultDurationSeconds: defaultDurationSeconds,
        defaultWeight: defaultWeight,
        notes: notes,
        targetedBodyPart: targetedBodyPart,
      );
      unawaited(sync?.uploadMasterWorkout(model));
      unawaited(sync?.uploadSessionWorkout(model));
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, Workout>> updateWorkout({
    required int id,
    required String exerciseName,
    required int defaultSets,
    required int defaultReps,
    int? defaultDurationSeconds,
    double? defaultWeight,
    String notes = '',
    BodyPart? targetedBodyPart,
  }) async {
    return _guard(() async {
      final model = await dataSource.update(
        id: id.toString(),
        exerciseName: exerciseName,
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        defaultDurationSeconds: defaultDurationSeconds,
        defaultWeight: defaultWeight,
        notes: notes,
        targetedBodyPart: targetedBodyPart,
      );
      unawaited(sync?.uploadMasterWorkout(model));
      unawaited(sync?.uploadSessionWorkout(model));
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteWorkout(int id) async {
    return _guard(() async {
      await dataSource.delete(id.toString());
      // The data source deletes the Firestore row directly (via the
      // DAO). We don't need to re-issue `sync.deleteSessionWorkout`
      // here — the DAO's deleteById already handles the cloud side.
      return Unit.instance;
    });
  }

  @override
  Future<Either<Failure, Unit>> reorderWorkouts({
    required int sessionId,
    required List<int> orderedIds,
  }) async {
    return _guard(() async {
      final sessionFid = await _resolveSessionFirestoreId(sessionId);
      final reordered = await dataSource.reorder(
        sessionId: sessionFid,
        orderedIds: orderedIds.map((id) => id.toString()).toList(),
      );
      // Mirror every row's new position to Firestore.
      for (final model in reordered) {
        unawaited(sync?.uploadSessionWorkout(model));
      }
      return Unit.instance;
    });
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      final value = await body();
      return Right(value);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (error) {
      return Left(UnexpectedFailure(message: 'Unexpected error', cause: error));
    }
  }

  /// Resolves the int id (a `firestoreId.hashCode`) to its Firestore
  /// document id by scanning the full session list. There is no
  /// server-side index keyed by int hash, so this is a local scan;
  /// the Firestore SDK caches the result so repeated calls are cheap.
  Future<String> _resolveSessionFirestoreId(int id) async {
    final all = await sessionDataSource.getAll();
    for (final s in all) {
      if (s.id == id && s.firestoreId != null) return s.firestoreId!;
    }
    // Fallback: the caller might already have a Firestore id.
    // Returning the toString of the int keeps the call shape valid
    // for stream subscribers that pass the int through unchanged.
    return id.toString();
  }
}