import 'package:drift/drift.dart';

import 'sessions_table.dart';

/// A single "workout day" — one row per (session, calendar-day) pair.
///
/// On [Today], starting a session creates a new [WorkoutLogs] row keyed by
/// the session and the day's date. All sets/reps/weights for the day are
/// stored as child [WorkoutLogEntries] so the source [Sessions] row (the
/// template) is never mutated by daily tracking.
///
/// Designed so we can later produce:
///   - Workout History: rows ordered by performed_at
///   - Calendar: rows grouped by performed_at date
///   - Daily Logs: one row + entries per day
///   - Dashboard / Weekly / Monthly stats: aggregate by date range
///   - Personal Records: max(weight) per [workoutId] over time
///   - Workout Streak: distinct date(days) over recent rows
@DataClassName('WorkoutLog')
class WorkoutLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The session template that was performed.
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();

  /// Calendar day the workout was performed on (start of day, local TZ).
  DateTimeColumn get performedAt => dateTime()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().nullable()();
}
