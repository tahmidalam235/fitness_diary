import 'package:drift/drift.dart';

import 'sessions_table.dart';
import 'workouts_table.dart';

/// Join table linking a [Session] to a master [Workout] with per-session
/// default values (sets / reps / duration / weight) and a manual ordering.
///
/// Reordering is driven by the [position] column; lower positions render
/// first. Position uniqueness per session is enforced via an index.
///
/// This table represents the **template** attached to a session. It is
/// read as the basis for new daily workout logs but is never updated by
/// day-to-day tracking — day tracking writes to [WorkoutLogs] /
/// [WorkoutLogEntries] so the template stays pristine.
@DataClassName('SessionWorkout')
class SessionWorkouts extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();

  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();

  IntColumn get position => integer()();

  IntColumn get defaultSets => integer().withDefault(const Constant(3))();

  IntColumn get defaultReps => integer().withDefault(const Constant(10))();

  IntColumn get defaultDurationSeconds => integer().nullable()();

  /// Suggested starting weight (kg / lb — agnostic).
  RealColumn get defaultWeight => real().nullable()();

  TextColumn get notes => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {sessionId, position},
        {sessionId, workoutId},
      ];
}
