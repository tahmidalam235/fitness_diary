// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_log_freeze_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkoutLogFreezeDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkoutLogFreezesTable get workoutLogFreezes =>
      attachedDatabase.workoutLogFreezes;
  WorkoutLogFreezeDaoManager get managers => WorkoutLogFreezeDaoManager(this);
}

class WorkoutLogFreezeDaoManager {
  final _$WorkoutLogFreezeDaoMixin _db;
  WorkoutLogFreezeDaoManager(this._db);
  $$WorkoutLogFreezesTableTableManager get workoutLogFreezes =>
      $$WorkoutLogFreezesTableTableManager(
        _db.attachedDatabase,
        _db.workoutLogFreezes,
      );
}
