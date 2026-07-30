import 'package:drift/drift.dart';

import 'workout_logs_table.dart';
import 'workouts_table.dart';

/// A single set entry recorded during a [WorkoutLog] day.
///
/// Every field is nullable / free-form so the user can record any subset
/// of (sets, reps, weight, duration, rest). This is the granular source of
/// truth for sets/reps/weight data, independent of the session template.
///
/// Fields:
///   - [workoutId]           : master workout this entry belongs to
///                             (kept even if master is renamed/deleted
///                             behaviour is left to FK rules).
///   - [setIndex]            : 1-based set number within the exercise
///   - [reps]                : completed reps (nullable)
///   - [weight]              : completed weight (nullable)
///   - [durationSeconds]     : completed duration in seconds (nullable)
///   - [restSeconds]         : rest after this set (nullable)
///   - [notes]               : optional per-set notes
///   - [position]            : manual ordering inside the workout
///
/// Designed for future aggregation: weekly / monthly progress is a sum or
/// average over a date range; PR is `MAX(weight)` per workoutId.
@DataClassName('WorkoutLogEntry')
class WorkoutLogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get workoutLogId =>
      integer().references(WorkoutLogs, #id, onDelete: KeyAction.cascade)();

  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();

  IntColumn get setIndex => integer()();

  IntColumn get position => integer()();

  /// Number of sets completed today for this exercise. Nullable so v7
  /// migrations backfill cleanly without breaking existing rows.
  IntColumn get sets => integer().nullable()();

  IntColumn get reps => integer().nullable()();

  RealColumn get weight => real().nullable()();

  IntColumn get durationSeconds => integer().nullable()();

  IntColumn get restSeconds => integer().nullable()();

  TextColumn get notes => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
