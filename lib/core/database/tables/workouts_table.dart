import 'package:drift/drift.dart';

/// Master catalog of exercises (e.g. Bench Press, Squat, Lat Pulldown).
///
/// Workouts are session-agnostic. They are attached to a session via the
/// [SessionWorkouts] join table.
@DataClassName('Workout')
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get exerciseName => text().withLength(min: 2, max: 80)();

  TextColumn get description => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
