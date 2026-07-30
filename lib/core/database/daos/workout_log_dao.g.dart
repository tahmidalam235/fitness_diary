// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_log_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkoutLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $SessionsTable get sessions => attachedDatabase.sessions;
  $WorkoutLogsTable get workoutLogs => attachedDatabase.workoutLogs;
  $WorkoutsTable get workouts => attachedDatabase.workouts;
  $WorkoutLogEntriesTable get workoutLogEntries =>
      attachedDatabase.workoutLogEntries;
  WorkoutLogDaoManager get managers => WorkoutLogDaoManager(this);
}

class WorkoutLogDaoManager {
  final _$WorkoutLogDaoMixin _db;
  WorkoutLogDaoManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$WorkoutLogsTableTableManager get workoutLogs =>
      $$WorkoutLogsTableTableManager(_db.attachedDatabase, _db.workoutLogs);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db.attachedDatabase, _db.workouts);
  $$WorkoutLogEntriesTableTableManager get workoutLogEntries =>
      $$WorkoutLogEntriesTableTableManager(
        _db.attachedDatabase,
        _db.workoutLogEntries,
      );
}
