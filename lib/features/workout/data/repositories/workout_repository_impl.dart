import 'dart:async';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/workout_local_datasource.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  const WorkoutRepositoryImpl({required this.dataSource});

  final WorkoutLocalDataSource dataSource;

  @override
  Stream<Either<Failure, List<Workout>>> watchWorkoutsForSession(
    int sessionId,
  ) {
    return dataSource
        .watchForSession(sessionId)
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
  Future<Either<Failure, Workout>> addWorkoutToSession({
    required int sessionId,
    required String exerciseName,
    required int defaultSets,
    required int defaultReps,
    int? defaultDurationSeconds,
    double? defaultWeight,
    String notes = '',
  }) async {
    return _guard(() async {
      final model = await dataSource.insert(
        sessionId: sessionId,
        exerciseName: exerciseName,
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        defaultDurationSeconds: defaultDurationSeconds,
        defaultWeight: defaultWeight,
        notes: notes,
      );
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
  }) async {
    return _guard(() async {
      final model = await dataSource.update(
        id: id,
        exerciseName: exerciseName,
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        defaultDurationSeconds: defaultDurationSeconds,
        defaultWeight: defaultWeight,
        notes: notes,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteWorkout(int id) async {
    return _guard(() async {
      await dataSource.delete(id);
      return Unit.instance;
    });
  }

  @override
  Future<Either<Failure, Unit>> reorderWorkouts({
    required int sessionId,
    required List<int> orderedIds,
  }) async {
    return _guard(() async {
      await dataSource.reorder(sessionId: sessionId, orderedIds: orderedIds);
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
}
