import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workouts_table.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [Workouts])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  Future<List<Workout>> getAllWorkouts() {
    return select(workouts).get();
  }

  Stream<List<Workout>> watchAllWorkouts() {
    return select(workouts).watch();
  }

  Future<List<Workout>> getWorkoutsBySession(int sessionId) {
    return (select(workouts)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.exerciseName)]))
        .get();
  }

  Stream<List<Workout>> watchWorkoutsBySession(int sessionId) {
    return (select(workouts)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.exerciseName)]))
        .watch();
  }

  Future<int> insertWorkout(WorkoutsCompanion companion) {
    return into(workouts).insert(companion);
  }

  Future<bool> updateWorkout(Workout workout) {
    return update(workouts).replace(workout);
  }

  Future<int> deleteWorkout(int id) {
    return (delete(workouts)..where((tbl) => tbl.id.equals(id))).go();
  }
}
