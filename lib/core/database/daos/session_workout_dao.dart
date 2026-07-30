import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/session_workouts_table.dart';

part 'session_workout_dao.g.dart';

/// Data-access object for the [SessionWorkouts] join table.
///
/// A row represents an exercise attached to a session template with
/// per-session default values. Reordering is driven by the [position]
/// column; lower positions render first. Position uniqueness per session
/// is enforced via an index.
///
/// Mutations from daily tracking must NOT touch this table — daily
/// tracking writes to [WorkoutLogDao].
@DriftAccessor(tables: [SessionWorkouts])
class SessionWorkoutDao extends DatabaseAccessor<AppDatabase>
    with _$SessionWorkoutDaoMixin {
  SessionWorkoutDao(super.db);

  Future<List<SessionWorkout>> getBySession(int sessionId) {
    return (select(sessionWorkouts)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .get();
  }

  Stream<List<SessionWorkout>> watchBySession(int sessionId) {
    return (select(sessionWorkouts)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .watch();
  }

  Future<int> insertSessionWorkout(SessionWorkoutsCompanion companion) {
    return into(sessionWorkouts).insert(companion);
  }

  Future<bool> updateSessionWorkout(SessionWorkout row) {
    return update(sessionWorkouts).replace(row);
  }

  Future<SessionWorkout?> getById(int id) {
    return (select(sessionWorkouts)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> deleteById(int id) {
    return (delete(sessionWorkouts)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> deleteBySession(int sessionId) {
    return (delete(sessionWorkouts)
          ..where((tbl) => tbl.sessionId.equals(sessionId)))
        .go();
  }

  /// Returns the next available [position] for a session.
  Future<int> nextPosition(int sessionId) async {
    final rows = await (selectOnly(sessionWorkouts)
          ..addColumns([sessionWorkouts.position.max()])
          ..where(sessionWorkouts.sessionId.equals(sessionId)))
        .getSingleOrNull();
    final maxPosition = rows?.read(sessionWorkouts.position.max());
    return (maxPosition ?? -1) + 1;
  }

  /// Persists a new ordering for [sessionId] from the supplied list of
  /// ids. Items not in [orderedIds] are left untouched.
  Future<void> reorderSession({
    required int sessionId,
    required List<int> orderedIds,
  }) async {
    await batch((batch) {
      for (var i = 0; i < orderedIds.length; i++) {
        batch.update(
          sessionWorkouts,
          SessionWorkoutsCompanion(position: Value(i)),
          where: (tbl) =>
              tbl.id.equals(orderedIds[i]) &
              tbl.sessionId.equals(sessionId),
        );
      }
    });
  }
}
