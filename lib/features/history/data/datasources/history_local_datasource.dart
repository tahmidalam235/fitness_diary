import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../core/error/exceptions.dart';
import '../../../workout/data/datasources/workout_local_datasource.dart';
import '../../../workout/data/models/workout_model.dart';
import '../../../workout_log/data/models/workout_log_model.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart'
    as entity;

/// Low-level read-only data source for the history feature.
///
/// Composes [WorkoutLogDao] (raw log/entry queries) with
/// [WorkoutLocalDataSource] (master workout lookup) so the repository
/// layer stays free of Drift types.
class HistoryLocalDataSource {
  const HistoryLocalDataSource({
    required this.workoutLogDao,
    required this.workoutLocalDataSource,
  });

  final WorkoutLogDao workoutLogDao;
  final WorkoutLocalDataSource workoutLocalDataSource;

  Stream<List<WorkoutLogModel>> watchLogsInRange({
    required DateTime start,
    required DateTime end,
  }) {
    try {
      return workoutLogDao
          .watchLogsInRange(start: start, end: end)
          .map<List<WorkoutLogModel>>(
        (rows) => <WorkoutLogModel>[
          for (final r in rows) WorkoutLogModel.fromDrift(r),
        ],
      );
    } catch (error) {
      throw DatabaseException(
        'Failed to watch workout history in range',
        cause: error,
      );
    }
  }

  Stream<List<WorkoutLogModel>> watchLogsForDay(DateTime day) {
    try {
      return workoutLogDao
          .watchLogsForDay(day)
          .map<List<WorkoutLogModel>>(
        (rows) => <WorkoutLogModel>[
          for (final r in rows) WorkoutLogModel.fromDrift(r),
        ],
      );
    } catch (error) {
      throw DatabaseException(
        'Failed to watch workout history for day',
        cause: error,
      );
    }
  }

  Stream<Map<int, List<entity.WorkoutLogEntry>>> watchEntriesByLogForDay(
    DateTime day,
  ) {
    try {
      return workoutLogDao.watchEntriesForDay(day).map(
        (rows) {
          final map = <int, List<entity.WorkoutLogEntry>>{};
          for (final r in rows) {
            map.putIfAbsent(r.logId, () => <entity.WorkoutLogEntry>[]).add(
              entity.WorkoutLogEntry(
                id: r.entry.id,
                workoutLogId: r.entry.workoutLogId,
                workoutId: r.entry.workoutId,
                setIndex: r.entry.setIndex,
                position: r.entry.position,
                reps: r.entry.reps,
                weight: r.entry.weight,
                durationSeconds: r.entry.durationSeconds,
                restSeconds: r.entry.restSeconds,
                notes: r.entry.notes,
              ),
            );
          }
          return map;
        },
      );
    } catch (error) {
      throw DatabaseException(
        'Failed to watch workout entries for day',
        cause: error,
      );
    }
  }

  Future<List<WorkoutModel>> getWorkoutsByIds(List<int> ids) {
    return workoutLocalDataSource.getByIds(ids);
  }
}