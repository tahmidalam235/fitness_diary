import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/session_dao.dart';
import 'daos/session_workout_dao.dart';
import 'daos/workout_dao.dart';
import 'daos/workout_log_dao.dart';
import 'tables/session_workouts_table.dart';
import 'tables/sessions_table.dart';
import 'tables/workout_log_entries_table.dart';
import 'tables/workout_logs_table.dart';
import 'tables/workouts_table.dart';

part 'app_database.g.dart';

/// Root Drift database. Owns all tables and DAOs.
///
/// Schema evolution:
///   v1: sessions, workouts, session_workouts.
///   v2: + sessions.updatedAt.
///   v3: + workout_logs, workout_log_entries,
///       session_workouts.default_weight, session_workouts.notes.
///   v4: self-healing cleanup of orphaned master `workouts` rows left
///       behind by partially-failed prior inserts (which would later
///       collide with the unique constraints on session_workouts and
///       surface as "Failed to add workout to session X" errors).
///   v5: self-healing migration that ensures the `workouts` table has a
///       `name` column. Older builds named this column differently
///       (`exercise_name`, `title`, etc.) or didn't have it at all when
///       the table was created by an out-of-band script — both of which
///       cause `INSERT INTO workouts (name) VALUES (?)` to fail with
///       `SQLiteException: table workouts has no column named "name"`.
///   v6: renames the `workouts.name` column to `exercise_name` to
///       better reflect its role as an exercise catalog and match the
///       Drift property `exerciseName`. This fix resolves the
///       "no column named name" error by ensuring the database matches
///       the expected schema.
///   v7: adds `workout_log_entries.sets` (nullable) so today's record can
///       carry the number of sets completed alongside reps/weight/
///       duration. Existing rows are left NULL — prefill logic uses the
///       session template defaults when NULL.
@DriftDatabase(
  tables: [Sessions, Workouts, SessionWorkouts, WorkoutLogs, WorkoutLogEntries],
  daos: [SessionDao, WorkoutDao, SessionWorkoutDao, WorkoutLogDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only constructor that accepts an in-memory [QueryExecutor].
  /// Production code must use the default constructor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(sessions, sessions.updatedAt);
        await m.createTable(sessionWorkouts);
        await customStatement(
          'UPDATE sessions SET updated_at = created_at '
          'WHERE updated_at IS NULL',
        );
      }
      if (from < 3) {
        await m.createTable(workoutLogs);
        await m.createTable(workoutLogEntries);
        await m.addColumn(sessionWorkouts, sessionWorkouts.defaultWeight);
        await m.addColumn(sessionWorkouts, sessionWorkouts.notes);
      }
      if (from < 4) {
        await _healOrphanedWorkouts();
      }
      if (from < 6) {
        await _ensureWorkoutsExerciseNameColumn();
      }
      if (from < 7) {
        await m.addColumn(workoutLogEntries, workoutLogEntries.sets);
      }
    },
  );

  /// Removes master `workouts` rows that are no longer referenced by any
  /// `session_workouts` row. Such orphans could only have been created by
  /// a partially-failed prior insert (the catalog is otherwise append-only
  /// and join rows always cascade on delete). Leaving them in place is
  /// harmless except that two distinct master rows can share a name,
  /// which is fine — but cleanup prevents the catalog from bloating over
  /// time and removes any latent cause for FK weirdness.
  Future<void> _healOrphanedWorkouts() async {
    await customStatement(
      'DELETE FROM workouts WHERE id NOT IN '
      '(SELECT DISTINCT workout_id FROM session_workouts)',
    );
  }

  /// Idempotently guarantees that the `workouts` table has an
  /// `exercise_name` column compatible with the current schema.
  ///
  /// Three on-device cases this has to survive:
  ///   1. The table exists with `exercise_name` already — no-op.
  ///   2. The table exists with a legacy column (`name`, `exerciseName`,
  ///      `title`) that we should adopt as the new `exercise_name`.
  ///   3. The table exists but has no usable name column at all (e.g.
  ///      created by an out-of-band script) — add an `exercise_name`
  ///      column with a default and backfill existing rows.
  Future<void> _ensureWorkoutsExerciseNameColumn() async {
    // Introspect the existing schema.
    final rows = await customSelect(
      'PRAGMA table_info(workouts)',
      readsFrom: {workouts},
    ).get();
    final existingColumns = <String>{
      for (final r in rows) (r.data['name'] as String),
    };

    if (existingColumns.contains('exercise_name')) {
      // Already in the correct shape.
      return;
    }

    // Try to rename a legacy column. Order matters: prefer 'name' first
    // if the v5 migration had already run, otherwise check other candidates.
    const legacyCandidates = ['name', 'exerciseName', 'title'];
    for (final legacy in legacyCandidates) {
      if (existingColumns.contains(legacy)) {
        await customStatement(
          'ALTER TABLE workouts RENAME COLUMN $legacy TO exercise_name',
        );
        return;
      }
    }

    // No usable source column.
    await customStatement(
      "ALTER TABLE workouts ADD COLUMN exercise_name TEXT NOT NULL DEFAULT ''",
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'fitness_diary.db'));
    return NativeDatabase.createInBackground(file);
  });
}
