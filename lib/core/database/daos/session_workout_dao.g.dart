// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_workout_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionWorkoutDaoMixin on DatabaseAccessor<AppDatabase> {
  $SessionsTable get sessions => attachedDatabase.sessions;
  $WorkoutsTable get workouts => attachedDatabase.workouts;
  $SessionWorkoutsTable get sessionWorkouts => attachedDatabase.sessionWorkouts;
  SessionWorkoutDaoManager get managers => SessionWorkoutDaoManager(this);
}

class SessionWorkoutDaoManager {
  final _$SessionWorkoutDaoMixin _db;
  SessionWorkoutDaoManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db.attachedDatabase, _db.workouts);
  $$SessionWorkoutsTableTableManager get sessionWorkouts =>
      $$SessionWorkoutsTableTableManager(
        _db.attachedDatabase,
        _db.sessionWorkouts,
      );
}
