import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../core/error/exceptions.dart';
import '../../../workout/data/datasources/workout_local_datasource.dart';
import '../../../workout/data/models/workout_model.dart';
import '../../../workout_log/data/models/workout_log_model.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart' as entity;

/// Firestore-backed adapter for the history feature.
///
/// Composes [WorkoutLogDao] (read-only Firestore queries) with
/// [WorkoutLocalDataSource] (master workout lookup) so the repository
/// layer stays free of Firestore-specific types.
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
      return workoutLogDao.watchLogsInRange(start: start, end: end);
    } catch (error) {
      throw DatabaseException(
        'Failed to watch workout history in range',
        cause: error,
      );
    }
  }

  Stream<List<WorkoutLogModel>> watchLogsForDay(DateTime day) {
    try {
      return workoutLogDao.watchLogsForDay(day);
    } catch (error) {
      throw DatabaseException(
        'Failed to watch workout history for day',
        cause: error,
      );
    }
  }

  Stream<Map<String, List<entity.WorkoutLogEntry>>> watchEntriesByLogForDay(
    DateTime day,
  ) {
    try {
      return workoutLogDao.watchEntriesForDay(day).map((rows) {
        final map = <String, List<entity.WorkoutLogEntry>>{};
        for (final r in rows) {
          map
              .putIfAbsent(r.logFid, () => <entity.WorkoutLogEntry>[])
              .add(
                entity.WorkoutLogEntry(
                  id: r.entry.id,
                  workoutLogId: r.entry.workoutLogId,
                  workoutId: r.entry.workoutId,
                  setIndex: r.entry.setIndex,
                  position: r.entry.position,
                  sets: r.entry.sets,
                  reps: r.entry.reps,
                  weight: r.entry.weight,
                  durationSeconds: r.entry.durationSeconds,
                  restSeconds: r.entry.restSeconds,
                  notes: r.entry.notes,
                  workoutFirestoreId: r.entry.workoutFirestoreId,
                ),
              );
        }
        return map;
      });
    } catch (error) {
      throw DatabaseException(
        'Failed to watch workout entries for day',
        cause: error,
      );
    }
  }

  Stream<List<entity.WorkoutLogEntry>> watchAllEntries() {
    try {
      return workoutLogDao.watchAllEntries().map(
        (models) => <entity.WorkoutLogEntry>[
          for (final m in models) m.toEntity(),
        ],
      );
    } catch (error) {
      throw DatabaseException(
        'Failed to watch all workout entries',
        cause: error,
      );
    }
  }

  Future<List<WorkoutModel>> getWorkoutsByIds(List<String> ids) {
    return workoutLocalDataSource.getByIds(ids);
  }

  /// Lookup by master workout Firestore id. Workers in the calendar's
  /// daily-details flow only have `WorkoutLogEntry.workoutFirestoreId`
  /// (which is the masterFirestoreId), so we need to query by that
  /// field rather than the join row's own `firestoreId` doc id.
  Future<List<WorkoutModel>> getWorkoutsByMasterIds(List<String> masterFids) {
    return workoutLocalDataSource.getByMasterIds(masterFids);
  }

  /// Returns a map of every workout's int id → its master firestoreId.
  /// Used by the repository layer to translate the int-keyed contract
  /// into Firestore ids.
  Future<Map<int, String>> getAllWorkoutFirestoreIds() {
    return workoutLocalDataSource.getAllWorkoutIds();
  }
}
