import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workouts_table.dart';

part 'workout_dao.g.dart';

/// Data-access object for the [Workouts] master catalog.
@DriftAccessor(tables: [Workouts])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  Future<List<Workout>> getAllWorkouts() {
    return (select(
      workouts,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.exerciseName)])).get();
  }

  Stream<List<Workout>> watchAllWorkouts() {
    return (select(
      workouts,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.exerciseName)])).watch();
  }

  Future<Workout?> getById(int id) {
    return (select(
      workouts,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<List<Workout>> getByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value(const <Workout>[]);
    return (select(workouts)..where((tbl) => tbl.id.isIn(ids))).get();
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
