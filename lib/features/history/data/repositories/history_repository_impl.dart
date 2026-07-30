import 'dart:async';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_datasource.dart';

/// Concrete implementation of [HistoryRepository] backed by the local
/// data source (Drift) — read-only, no mutations.
class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl({required this.dataSource});

  final HistoryLocalDataSource dataSource;

  Failure _mapError(Object error, String label) {
    return mapExceptionToFailure(
      error is AppException
          ? error
          : UnexpectedException(label, cause: error),
    );
  }

  @override
  Stream<Either<Failure, List<WorkoutLog>>> watchLogsInRange({
    required DateTime start,
    required DateTime end,
  }) async* {
    try {
      await for (final models
          in dataSource.watchLogsInRange(start: start, end: end)) {
        yield Right<Failure, List<WorkoutLog>>(
          <WorkoutLog>[for (final m in models) m.toEntity()],
        );
      }
    } catch (error) {
      yield Left<Failure, List<WorkoutLog>>(
        _mapError(error, 'Failed to watch workout history in range'),
      );
    }
  }

  @override
  Stream<Either<Failure, List<WorkoutLog>>> watchLogsForDay(DateTime day) async* {
    try {
      await for (final models in dataSource.watchLogsForDay(day)) {
        yield Right<Failure, List<WorkoutLog>>(
          <WorkoutLog>[for (final m in models) m.toEntity()],
        );
      }
    } catch (error) {
      yield Left<Failure, List<WorkoutLog>>(
        _mapError(error, 'Failed to watch workout history for day'),
      );
    }
  }

  @override
  Stream<Either<Failure, Map<int, List<WorkoutLogEntry>>>>
      watchEntriesByLogForDay(DateTime day) async* {
    try {
      await for (final map in dataSource.watchEntriesByLogForDay(day)) {
        yield Right<Failure, Map<int, List<WorkoutLogEntry>>>(map);
      }
    } catch (error) {
      yield Left<Failure, Map<int, List<WorkoutLogEntry>>>(
        _mapError(error, 'Failed to watch workout entries for day'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<int, Workout>>> getWorkoutsByIds(
    List<int> workoutIds,
  ) async {
    try {
      if (workoutIds.isEmpty) return const Right({});
      final models = await dataSource.getWorkoutsByIds(workoutIds);
      return Right<Failure, Map<int, Workout>>({
        for (final m in models) m.workoutId: m.toEntity(),
      });
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (error) {
      return Left(
        UnexpectedFailure(message: 'Unexpected error', cause: error),
      );
    }
  }
}