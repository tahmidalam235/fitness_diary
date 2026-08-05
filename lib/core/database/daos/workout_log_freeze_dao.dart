import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workout_log_freezes_table.dart';

part 'workout_log_freeze_dao.g.dart';

/// Data-access object for the [WorkoutLogFreezes] table.
///
/// The streak-freeze feature is intentionally narrow: it only needs to
/// (a) toggle a day on/off, (b) observe all currently-frozen days, and
/// (c) hand the frozen set to the streak calculator.
@DriftAccessor(tables: [WorkoutLogFreezes])
class WorkoutLogFreezeDao
    extends DatabaseAccessor<AppDatabase> with _$WorkoutLogFreezeDaoMixin {
  WorkoutLogFreezeDao(super.db);

  /// Idempotent insert. Re-inserting the same [day] is a no-op (we
  /// rely on the UNIQUE INDEX on `day` rather than a precondition
  /// read, so the call is still O(1)).
  ///
  /// Returns the inserted row id, or 0 if the row already existed.
  Future<int> insertFreeze(WorkoutLogFreezesCompanion row) async {
    return into(workoutLogFreezes)
        .insert(row, mode: InsertMode.insertOrIgnore);
  }

  /// Removes the freeze for the half-open range `[day, day + 1 day)`.
  /// Returns the number of rows deleted (0 if no freeze existed).
  Future<int> deleteFreezeForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (delete(workoutLogFreezes)
          ..where(
            (tbl) =>
                tbl.day.isBiggerOrEqualValue(start) &
                tbl.day.isSmallerThanValue(end),
          ))
        .go();
  }

  /// Reactive stream of every frozen day, normalized to midnight local.
  /// The streak calc treats `Set<DateTime>`-style membership so the
  /// date-only normalization matters.
  Stream<Set<DateTime>> watchFrozenDays() {
    return (select(workoutLogFreezes)..orderBy([(t) => OrderingTerm.asc(t.day)]))
        .watch()
        .map(
          (rows) => <DateTime>{
            for (final r in rows)
              DateTime(r.day.year, r.day.month, r.day.day),
          },
        );
  }

  /// Reactive stream of full freeze rows in a range. Used by the
  /// freeze page to render the toggle strip.
  Stream<List<WorkoutLogFreeze>> watchFreezesInRange({
    required DateTime start,
    required DateTime end,
  }) {
    return (select(workoutLogFreezes)
          ..where(
            (tbl) =>
                tbl.day.isBiggerOrEqualValue(start) &
                tbl.day.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.day)]))
        .watch();
  }
}
