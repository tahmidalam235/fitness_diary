import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/daos/session_dao.dart';
import '../../../../core/database/daos/session_workout_dao.dart';
import '../../../../core/database/daos/workout_dao.dart';
import '../../../../core/error/exceptions.dart';
import '../models/workout_model.dart';

/// Low-level local data source combining [WorkoutDao] and
/// [SessionWorkoutDao] to expose operations scoped to a single session.
class WorkoutLocalDataSource {
  const WorkoutLocalDataSource({
    required this.database,
    required this.sessionWorkoutDao,
    required this.workoutDao,
    this.sessionDao,
  });

  final db.AppDatabase database;
  final SessionWorkoutDao sessionWorkoutDao;
  final WorkoutDao workoutDao;
  final SessionDao? sessionDao;

  Stream<List<WorkoutModel>> watchForSession(int sessionId) {
    try {
      return sessionWorkoutDao.watchBySession(sessionId).asyncMap((rows) async {
        if (rows.isEmpty) return const <WorkoutModel>[];
        final ids = rows.map((r) => r.workoutId).toSet();
        final masters = await workoutDao.getByIds(ids.toList());
        final byId = {for (final w in masters) w.id: w};
        return <WorkoutModel>[
          for (final r in rows)
            if (byId[r.workoutId] case final master?)
              WorkoutModel.fromJoin(master, r),
        ];
      });
    } catch (error) {
      throw DatabaseException(
        'Failed to watch workouts for session $sessionId',
        cause: error,
      );
    }
  }

  Future<WorkoutModel> insert({
    required int sessionId,
    required String exerciseName,
    required int defaultSets,
    required int defaultReps,
    int? defaultDurationSeconds,
    double? defaultWeight,
    required String notes,
  }) async {
    if (sessionId <= 0) {
      throw ValidationException(
        'Invalid session id',
        errors: {'sessionId': 'Invalid session id'},
      );
    }

    final sessionDao = this.sessionDao ?? SessionDao(database);

    // Run the entire insert in a single Drift transaction. This gives us:
    //   - atomicity: either the master + join + position step all land or
    //     none of them do (no half-state left in the DB that the orphaned
    //     cleanup has to chase on a future call);
    //   - serialised writes against the same connection (the concurrent
    //     watch stream can't interleave between our three statements);
    //   - clear rollback semantics so a UNIQUE/CHECK violation anywhere
    //     reverts the master row instead of leaving a phantom workout.
    //
    // We surface the failing step in the error message so the next time
    // something blows up we know exactly which SQL statement to look at.
    try {
      final inserted = await database.transaction(() async {
        final parent = await sessionDao.getSessionById(sessionId);
        if (parent == null) {
          throw NotFoundException('Session $sessionId does not exist');
        }

        // Heal any orphaned master workout rows. Idempotent: only deletes
        // rows that have no join-row referencing them. Stale rows could
        // only exist from a prior insert that crashed between Step 1 and
        // Step 3 of the legacy code path.
        await database.customStatement(
          'DELETE FROM workouts WHERE id NOT IN '
          '(SELECT DISTINCT workout_id FROM session_workouts)',
        );

        // Step 1: insert master workout row.
        final workoutId = await workoutDao.insertWorkout(
          db.WorkoutsCompanion.insert(exerciseName: exerciseName),
        );

        // Step 2: compute a safe position. We take max(position)+1 from
        // existing rows in this session and shift it past any positions
        // that are already taken (handles legacy gaps and stale data).
        final nextPosition = await sessionWorkoutDao.nextPosition(sessionId);
        final existingRows = await sessionWorkoutDao.getBySession(sessionId);
        final taken = <int>{for (final r in existingRows) r.position};
        var safePosition = nextPosition;
        while (taken.contains(safePosition)) {
          safePosition += 1;
        }

        // Step 3: insert the join row.
        final swId = await sessionWorkoutDao.insertSessionWorkout(
          db.SessionWorkoutsCompanion.insert(
            sessionId: sessionId,
            workoutId: workoutId,
            position: safePosition,
            defaultSets: Value(defaultSets),
            defaultReps: Value(defaultReps),
            defaultDurationSeconds: Value(defaultDurationSeconds),
            defaultWeight: Value(defaultWeight),
            notes: Value(notes),
          ),
        );

        return (workoutId: workoutId, swId: swId);
      });

      // Step 4: read back the inserted rows for the return value. This
      // happens outside the transaction so a transient read miss after
      // commit doesn't roll back the writes.
      final master = await workoutDao.getById(inserted.workoutId);
      final join = await sessionWorkoutDao.getById(inserted.swId);
      if (master == null || join == null) {
        throw const UnexpectedException('Insert succeeded but rows missing');
      }
      return WorkoutModel.fromJoin(master, join);
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to add workout to session $sessionId: $error',
        cause: error,
      );
    }
  }

  Future<WorkoutModel> update({
    required int id,
    required String exerciseName,
    required int defaultSets,
    required int defaultReps,
    int? defaultDurationSeconds,
    double? defaultWeight,
    required String notes,
  }) async {
    try {
      final join = await sessionWorkoutDao.getById(id);
      if (join == null) {
        throw NotFoundException('SessionWorkout $id not found');
      }
      final master = await workoutDao.getById(join.workoutId);
      if (master == null) {
        throw NotFoundException('Workout ${join.workoutId} not found');
      }
      await workoutDao.updateWorkout(
        master.copyWith(exerciseName: exerciseName),
      );

      final updated = join.copyWith(
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        defaultDurationSeconds: Value(defaultDurationSeconds),
        defaultWeight: Value(defaultWeight),
        notes: notes,
      );
      await sessionWorkoutDao.updateSessionWorkout(updated);
      final freshMaster = await workoutDao.getById(join.workoutId);
      if (freshMaster == null) {
        throw const UnexpectedException('Master workout vanished after update');
      }
      return WorkoutModel.fromJoin(freshMaster, updated);
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to update workout $id: $error',
        cause: error,
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      final join = await sessionWorkoutDao.getById(id);
      if (join == null) {
        throw NotFoundException('SessionWorkout $id not found');
      }
      await sessionWorkoutDao.deleteById(id);
      final remaining = await sessionWorkoutDao.getBySession(join.sessionId);
      final stillUsed = remaining.any((r) => r.workoutId == join.workoutId);
      if (!stillUsed) {
        await workoutDao.deleteWorkout(join.workoutId);
      }
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException('Failed to delete workout $id', cause: error);
    }
  }

  Future<void> reorder({
    required int sessionId,
    required List<int> orderedIds,
  }) async {
    try {
      await sessionWorkoutDao.reorderSession(
        sessionId: sessionId,
        orderedIds: orderedIds,
      );
    } catch (error) {
      throw DatabaseException(
        'Failed to reorder workouts for session $sessionId',
        cause: error,
      );
    }
  }

  /// Bulk lookup of master workouts by id.
  Future<List<WorkoutModel>> getByIds(List<int> ids) async {
    try {
      if (ids.isEmpty) return const <WorkoutModel>[];
      final rows = await workoutDao.getByIds(ids);
      return <WorkoutModel>[for (final r in rows) WorkoutModel.fromMaster(r)];
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException('Failed to load workouts by ids', cause: error);
    }
  }
}
