import 'dart:async';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../../../session/data/datasources/session_local_datasource.dart';
import '../../../workout/data/datasources/workout_local_datasource.dart';
import '../../domain/entities/workout_log.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../../domain/repositories/workout_log_repository.dart';
import '../datasources/workout_log_local_datasource.dart';
import '../models/workout_log_entry_model.dart';

/// Firestore-backed implementation of [WorkoutLogRepository].
///
/// The data source handles cloud I/O directly; the sync service is
/// used as a defensive re-emit of the latest model state.
class WorkoutLogRepositoryImpl implements WorkoutLogRepository {
  const WorkoutLogRepositoryImpl({
    required this.dataSource,
    required this.sessionDataSource,
    required this.workoutLocalDataSource,
    this.sync,
  });

  final WorkoutLogLocalDataSource dataSource;
  final SessionLocalDataSource sessionDataSource;
  final WorkoutLocalDataSource workoutLocalDataSource;
  final SyncService? sync;

  @override
  Future<Either<Failure, WorkoutLog>> getOrCreateTodayLog(int sessionId) {
    return _guard(() async {
      final sessionFid = await _resolveSessionFirestoreId(sessionId);
      final model = await dataSource.getOrCreateTodayLog(sessionFid);
      // Only sync on create — re-opening an existing log is a no-op.
      if (model.firestoreId != null) {
        unawaited(sync?.uploadWorkoutLog(model));
      }
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, WorkoutLog?>> findTodayLog(int sessionId) {
    return _guard(() async {
      final sessionFid = await _resolveSessionFirestoreId(sessionId);
      final model = await dataSource.findTodayLog(sessionFid);
      return model?.toEntity();
    });
  }

  @override
  Stream<Either<Failure, Map<int, WorkoutLogEntry>>> watchTodayEntriesByWorkout(
    int sessionId,
  ) {
    return _resolveSessionFirestoreId(sessionId).asStream().asyncExpand((
      sessionFid,
    ) {
      return dataSource
          .watchTodayEntriesByWorkout(sessionFid)
          .map<Either<Failure, Map<int, WorkoutLogEntry>>>((models) {
            return Right<Failure, Map<int, WorkoutLogEntry>>({
              for (final m in models.values) m.workoutId: m.toEntity(),
            });
          })
          .handleError(
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
    });
  }

  @override
  Future<Either<Failure, WorkoutLogEntry>> upsertEntry(WorkoutLogEntry entry) {
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
          firestoreId: entry.firestoreId,
          workoutLogFirestoreId: entry.workoutLogFirestoreId,
          workoutFirestoreId: entry.workoutFirestoreId,
        ),
      );
      unawaited(sync?.uploadWorkoutLogEntry(model));
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteEntry(int id) {
    return _guard(() async {
      // 1. Resolve the Firestore ID for the entry and its parent log
      // BEFORE deleting the entry, so we can check the parent's state
      // after the deletion.
      final entryFid = await dataSource.resolveEntryFirestoreId(id.toString());
      if (entryFid == null || entryFid.isEmpty) return Unit.instance;

      final logFid = await dataSource.entryWorkoutLogFirestoreId(entryFid);

      // 2. Perform the deletion.
      await dataSource.deleteEntry(entryFid);

      // Mirror a second delete via sync as a defensive re-emit (idempotent).
      unawaited(sync?.deleteWorkoutLogEntry(entryFid));

      // 3. Garbage-collect the parent log if it now has zero surviving
      // entries. The Today page and Calendar history will re-render
      // automatically via their push-based watchers.
      if (logFid != null && logFid.isNotEmpty) {
        final remaining = await dataSource.getEntriesForLog(logFid);
        if (remaining.isEmpty) {
          unawaited(sync?.deleteWorkoutLog(logFid));
        }
      }

      return Unit.instance;
    });
  }

  @override
  Future<Either<Failure, WorkoutLog>> addWorkoutsToToday({
    required int sessionId,
    required List<WorkoutLogEntry> entries,
  }) {
    return _guard(() async {
      final sessionFid = await _resolveSessionFirestoreId(sessionId);
      final result = await dataSource.addWorkoutsToToday(
        sessionFirestoreId: sessionFid,
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
              workoutFirestoreId: e.workoutFirestoreId,
            ),
        ],
      );
      unawaited(sync?.uploadWorkoutLog(result.log));
      for (final entry in result.entries) {
        unawaited(sync?.uploadWorkoutLogEntry(entry));
      }
      return result.log.toEntity();
    });
  }

  @override
  Future<Either<Failure, Map<int, WorkoutLogEntry>>> getLastEntriesForWorkouts(
    List<int> workoutIds,
  ) async {
    try {
      final idMap = await workoutLocalDataSource.getAllWorkoutIds();
      final workoutFids = <String>[
        for (final id in workoutIds)
          if (idMap[id] != null) idMap[id]!,
      ];
      final models = await dataSource.getLastEntriesForWorkouts(workoutFids);
      return Right<Failure, Map<int, WorkoutLogEntry>>({
        for (final m in models.values)
          if (m.workoutId != 0) m.workoutId: m.toEntity(),
      });
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (error) {
      return Left(UnexpectedFailure(message: 'Unexpected error', cause: error));
    }
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

  Future<String> _resolveSessionFirestoreId(int id) async {
    final all = await sessionDataSource.getAll();
    for (final s in all) {
      if (s.id == id && s.firestoreId != null) return s.firestoreId!;
    }
    return id.toString();
  }
}
