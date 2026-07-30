import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workout_log_entries_table.dart';
import '../tables/workout_logs_table.dart';

part 'workout_log_dao.g.dart';

/// Data-access object for daily workout logs.
///
/// A [WorkoutLog] is a snapshot of a session performed on a given day;
/// child [WorkoutLogEntries] store per-set data (reps, weight, duration,
/// rest, notes). Both tables are append-only from the template's point of
/// view — the source [Sessions] / [SessionWorkouts] rows are never
/// modified by daily tracking.
@DriftAccessor(tables: [WorkoutLogs, WorkoutLogEntries])
class WorkoutLogDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutLogDaoMixin {
  WorkoutLogDao(super.db);

  // ---------------------------------------------------------------------------
  // Logs
  // ---------------------------------------------------------------------------

  Future<int> insertLog(WorkoutLogsCompanion companion) {
    return into(workoutLogs).insert(companion);
  }

  Future<bool> updateLog(WorkoutLog log) {
    return update(workoutLogs).replace(log);
  }

  Future<int> deleteLog(int id) {
    return (delete(workoutLogs)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<WorkoutLog?> getLogById(int id) {
    return (select(workoutLogs)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<WorkoutLog>> watchAllLogs() {
    return (select(workoutLogs)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.performedAt)]))
        .watch();
  }

  Future<WorkoutLog?> findLogForDay({
    required int sessionId,
    required DateTime day,
  }) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(workoutLogs)
          ..where((tbl) =>
              tbl.sessionId.equals(sessionId) &
              tbl.performedAt.isBiggerOrEqualValue(start) &
              tbl.performedAt.isSmallerThanValue(end))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.performedAt)]))
        .getSingleOrNull();
  }

  Stream<WorkoutLog?> watchLogForDay({
    required int sessionId,
    required DateTime day,
  }) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(workoutLogs)
          ..where((tbl) =>
              tbl.sessionId.equals(sessionId) &
              tbl.performedAt.isBiggerOrEqualValue(start) &
              tbl.performedAt.isSmallerThanValue(end))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.performedAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// All logs whose [WorkoutLog.performedAt] falls inside the half-open
  /// range `[start, end)`. Used by the calendar to render highlighting dots
  /// for a visible month.
  Stream<List<WorkoutLog>> watchLogsInRange({
    required DateTime start,
    required DateTime end,
  }) {
    return (select(workoutLogs)
          ..where((tbl) =>
              tbl.performedAt.isBiggerOrEqualValue(start) &
              tbl.performedAt.isSmallerThanValue(end))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.performedAt)]))
        .watch();
  }

  /// Every log performed on the given calendar [day]. A day may contain
  /// multiple logs (one per session performed on that day).
  Stream<List<WorkoutLog>> watchLogsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(workoutLogs)
          ..where((tbl) =>
              tbl.performedAt.isBiggerOrEqualValue(start) &
              tbl.performedAt.isSmallerThanValue(end))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.performedAt)]))
        .watch();
  }

  /// All entries for every log performed on the given calendar [day],
  /// joined with the parent [WorkoutLog] so we can group entries by log.
  /// Returns a list of rows where each row exposes the entry plus its
  /// parent log id (read via the join key).
  Stream<List<DayEntryRow>> watchEntriesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final query = select(workoutLogEntries).join([
      leftOuterJoin(
        workoutLogs,
        workoutLogs.id.equalsExp(workoutLogEntries.workoutLogId),
      ),
    ])
      ..where(workoutLogs.performedAt.isBiggerOrEqualValue(start) &
          workoutLogs.performedAt.isSmallerThanValue(end))
      ..orderBy([
        OrderingTerm.asc(workoutLogEntries.position),
        OrderingTerm.asc(workoutLogEntries.setIndex),
      ]);
    return query.watch().map(
          (rows) => <DayEntryRow>[
            for (final r in rows)
              DayEntryRow(
                entry: r.readTable(workoutLogEntries),
                logId: r.readTable(workoutLogs).id,
              ),
          ],
        );
  }

  // ---------------------------------------------------------------------------
  // Entries
  // ---------------------------------------------------------------------------

  Future<int> insertEntry(WorkoutLogEntriesCompanion companion) {
    return into(workoutLogEntries).insert(companion);
  }

  Future<bool> updateEntry(WorkoutLogEntry entry) {
    return update(workoutLogEntries).replace(entry);
  }

  Future<int> deleteEntry(int id) {
    return (delete(workoutLogEntries)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<List<WorkoutLogEntry>> getEntriesForLog(int logId) {
    return (select(workoutLogEntries)
          ..where((tbl) => tbl.workoutLogId.equals(logId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.position),
            (tbl) => OrderingTerm.asc(tbl.setIndex),
          ]))
        .get();
  }

  Stream<List<WorkoutLogEntry>> watchEntriesForLog(int logId) {
    return (select(workoutLogEntries)
          ..where((tbl) => tbl.workoutLogId.equals(logId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.position),
            (tbl) => OrderingTerm.asc(tbl.setIndex),
          ]))
        .watch();
  }

  /// Streams the single entry per workout for today's log, keyed by
  /// workoutId. The contract for v7+ is that there is exactly one row
  /// per `(workoutLogId, workoutId)` per day, so this collapses the list
  /// into a map the UI can index directly.
  Stream<Map<int, WorkoutLogEntry>> watchEntriesByWorkoutForLog(int logId) {
    return (select(workoutLogEntries)
          ..where((tbl) => tbl.workoutLogId.equals(logId)))
        .watch()
        .map<Map<int, WorkoutLogEntry>>((rows) {
      final map = <int, WorkoutLogEntry>{};
      for (final r in rows) {
        map[r.workoutId] = r;
      }
      return map;
    });
  }

  /// Returns the most recent prior entry per workout id (excluding
  /// entries that belong to today's log). Used by the prefill flow so
  /// the tracking card can be seeded with yesterday's values.
  Future<Map<int, WorkoutLogEntry>> getLastEntriesForWorkouts(
    List<int> workoutIds, {
    required DateTime beforeDay,
  }) async {
    if (workoutIds.isEmpty) return const {};
    final cutoff = DateTime(beforeDay.year, beforeDay.month, beforeDay.day);
    // Pull every entry for the requested workouts strictly before today
    // and pick the newest per workout. Keeps the query small for typical
    // session sizes (a handful of exercises).
    final query = select(workoutLogEntries).join([
      innerJoin(
        workoutLogs,
        workoutLogs.id.equalsExp(workoutLogEntries.workoutLogId),
      ),
    ])
      ..where(workoutLogEntries.workoutId.isIn(workoutIds) &
          workoutLogs.performedAt.isSmallerThanValue(cutoff))
      ..orderBy([OrderingTerm.desc(workoutLogs.performedAt)]);
    final rows = await query.get();
    final out = <int, WorkoutLogEntry>{};
    for (final row in rows) {
      final entry = row.readTable(workoutLogEntries);
      if (out.containsKey(entry.workoutId)) continue;
      out[entry.workoutId] = entry;
    }
    return out;
  }
}

/// A joined row returned by [WorkoutLogDao.watchEntriesForDay]: the entry
/// plus its parent log id, used to group entries by log in the history
/// read path.
class DayEntryRow {
  const DayEntryRow({required this.entry, required this.logId});

  final WorkoutLogEntry entry;
  final int logId;
}
