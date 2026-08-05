import 'package:drift/drift.dart';

/// Per-day streak-freeze markers.
///
/// A freeze marks a specific calendar day as an intentional rest day so
/// the streak counter in the Progress section doesn't reset on days the
/// user didn't (and didn't intend to) train.
///
/// Schema v9 migration creates this table. Uniqueness on `day` is
/// enforced via a UNIQUE INDEX (same pattern as `users.username` in v8)
/// so the DAO can treat `insertFreeze` as idempotent.
@DataClassName('WorkoutLogFreeze')
class WorkoutLogFreezes extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Calendar day the freeze applies to (start of day, local TZ).
  DateTimeColumn get day => dateTime()();

  /// Optional free-text reason ("travel", "rest", "sick").
  TextColumn get note => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
