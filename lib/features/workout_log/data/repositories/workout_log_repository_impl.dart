import 'dart:async';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../../domain/entities/workout_log.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../../domain/repositories/workout_log_repository.dart';
import '../datasources/workout_log_local_datasource.dart';
import '../models/workout_log_entry_model.dart';

class WorkoutLogRepositoryImpl implements WorkoutLogRepository {
  const WorkoutLogRepositoryImpl({required this.dataSource});

  final WorkoutLogLocalDataSource dataSource;

  @override
  Future<Either<Failure, WorkoutLog>> getOrCreateTodayLog(int sessionId) {
    return _guard(() async {
      final model = await dataSource.getOrCreateTodayLog(sessionId);
      return model.toEntity();
    });
  }

  @override
  Stream<Either<Failure, Map<int, WorkoutLogEntry>>>
      watchTodayEntriesByWorkout(int sessionId) {
    return dataSource
        .watchTodayEntriesByWorkout(sessionId)
        .map<Either<Failure, Map<int, WorkoutLogEntry>>>(
      (models) {
        return Right<Failure, Map<int, WorkoutLogEntry>>({
          for (final m in models.values) m.workoutId: m.toEntity(),
        });
      },
    ).handleError(
      (Object error) => Left<Failure, Map<int, WorkoutLogEntry>>(
        mapExceptionToFailure(
          error is AppException
              ? error
              : UnexpectedException(
                  'Failed to watch today\'s workout entries',
                  cause: error,
                ),
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, WorkoutLogEntry>> upsertEntry(
    WorkoutLogEntry entry,
  ) {
    return _guard(() async {
      final model = await dataSource.upsertEntry(
        WorkoutLogEntryModel(
          id: entry.id,
          workoutLogId: entry.workoutLogId,
          workoutId: entry.workoutId,
          setIndex: entry.setIndex,
          position: entry.position,
          sets: entry.sets,
          reps: entry.reps,
          weight: entry.weight,
          durationSeconds: entry.durationSeconds,
          restSeconds: entry.restSeconds,
          notes: entry.notes,
        ),
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteEntry(int id) {
    return _guard(() async {
      await dataSource.deleteEntry(id);
      return Unit.instance;
    });
  }

  @override
  Future<Either<Failure, WorkoutLog>> addWorkoutsToToday({
    required int sessionId,
    required List<WorkoutLogEntry> entries,
  }) {
    return _guard(() async {
      final log = await dataSource.addWorkoutsToToday(
        sessionId: sessionId,
        entries: <WorkoutLogEntryModel>[
          for (final e in entries)
            WorkoutLogEntryModel(
              id: 0,
              workoutLogId: e.workoutLogId,
              workoutId: e.workoutId,
              setIndex: 1,
              position: 0,
              sets: e.sets,
              reps: e.reps,
              weight: e.weight,
              durationSeconds: e.durationSeconds,
              restSeconds: e.restSeconds,
              notes: e.notes,
            ),
        ],
      );
      return log.toEntity();
    });
  }

  @override
  Future<Either<Failure, Map<int, WorkoutLogEntry>>>
      getLastEntriesForWorkouts(List<int> workoutIds) async {
    try {
      final models =
          await dataSource.getLastEntriesForWorkouts(workoutIds);
      return Right<Failure, Map<int, WorkoutLogEntry>>({
        for (final m in models.values) m.workoutId: m.toEntity(),
      });
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (error) {
      return Left(
        UnexpectedFailure(message: 'Unexpected error', cause: error),
      );
    }
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      final value = await body();
      return Right(value);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (error) {
      return Left(
        UnexpectedFailure(message: 'Unexpected error', cause: error),
      );
    }
  }
}
