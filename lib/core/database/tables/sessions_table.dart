import 'package:drift/drift.dart';

/// Workout-session templates (e.g. Push, Pull, Legs).
///
/// A session groups a set of master workouts and serves as a reusable
/// template for daily workout logging.
@DataClassName('Session')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 2, max: 60)();

  TextColumn get description =>
      text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Nullable in v2 to allow backfill during migration; will be tightened
  /// to NOT NULL in v3 once all installs have been upgraded at least once.
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
