import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/daos/session_workout_dao.dart';
import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../core/error/exceptions.dart';
import '../models/workout_log_entry_model.dart';
import '../models/workout_log_model.dart';

class WorkoutLogLocalDataSource {
  const WorkoutLogLocalDataSource({
    required this.workoutLogDao,
    required this.sessionWorkoutDao,
  });

  final WorkoutLogDao workoutLogDao;
  final SessionWorkoutDao sessionWorkoutDao;

  Future<WorkoutLogModel> getOrCreateTodayLog(int sessionId) async {
    try {
      final today = DateTime.now();
      final existing =
          await workoutLogDao.findLogForDay(sessionId: sessionId, day: today);
      if (existing != null) {
        return WorkoutLogModel.fromDrift(existing);
      }
      final id = await workoutLogDao.insertLog(
        db.WorkoutLogsCompanion.insert(
          sessionId: sessionId,
          performedAt: DateTime(today.year, today.month, today.day),
        ),
      );
      final fresh = await workoutLogDao.getLogById(id);
      if (fresh == null) {
        throw const UnexpectedException('Inserted log not found');
      }
      return WorkoutLogModel.fromDrift(fresh);
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to load today\'s workout log',
        cause: error,
      );
    }
  }

  /// Streams today's entries for [sessionId] as a `Map<workoutId, entry>`
  /// so the UI can look up the single row per workout directly.
  Stream<Map<int, WorkoutLogEntryModel>> watchTodayEntriesByWorkout(
    int sessionId,
  ) async* {
    try {
      final log = await workoutLogDao.findLogForDay(
        sessionId: sessionId,
        day: DateTime.now(),
      );
      if (log == null) {
        yield const <int, WorkoutLogEntryModel>{};
        return;
      }
      yield* workoutLogDao.watchEntriesByWorkoutForLog(log.id).map(
        (map) {
          return <int, WorkoutLogEntryModel>{
            for (final entry in map.values)
              entry.workoutId: WorkoutLogEntryModel.fromDrift(entry),
          };
        },
      );
    } catch (error) {
      throw DatabaseException(
        'Failed to watch today\'s workout entries',
        cause: error,
      );
    }
  }

  Future<WorkoutLogEntryModel> upsertEntry(WorkoutLogEntryModel model) async {
    try {
      if (model.id == 0) {
        final id = await workoutLogDao.insertEntry(
          model.toInsertCompanion(),
        );
        return model.copyWith(id: id);
      }
      await workoutLogDao.updateEntry(model.toDrift());
      return model;
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to upsert workout log entry',
        cause: error,
      );
    }
  }

  Future<void> deleteEntry(int id) async {
    try {
      await workoutLogDao.deleteEntry(id);
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to delete workout log entry',
        cause: error,
      );
    }
  }

  /// Adds the given entries to today's log for [sessionId] (creating
  /// the log row lazily). One entry per selected workout — the
  /// single-card model assumes exactly one row per workout per day.
  Future<WorkoutLogModel> addWorkoutsToToday({
    required int sessionId,
    required List<WorkoutLogEntryModel> entries,
  }) async {
    try {
      final log = await getOrCreateTodayLog(sessionId);
      for (final entry in entries) {
        await workoutLogDao.insertEntry(
          entry.copyWith(id: 0, workoutLogId: log.id).toInsertCompanion(),
        );
      }
      return log;
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to add workouts to today\'s log',
        cause: error,
      );
    }
  }

  /// Returns the most recent prior entry per workout id (excluding
  /// today). Used to prefill the tracking card with yesterday's values.
  Future<Map<int, WorkoutLogEntryModel>> getLastEntriesForWorkouts(
    List<int> workoutIds,
  ) async {
    try {
      final today = DateTime.now();
      final rows = await workoutLogDao.getLastEntriesForWorkouts(
        workoutIds,
        beforeDay: today,
      );
      return <int, WorkoutLogEntryModel>{
        for (final entry in rows.values)
          entry.workoutId: WorkoutLogEntryModel.fromDrift(entry),
      };
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to load previous workout entries',
        cause: error,
      );
    }
  }
}
