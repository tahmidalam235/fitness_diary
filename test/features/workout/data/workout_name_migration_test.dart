import 'package:drift/native.dart';
import 'package:fitness_diary/core/database/app_database.dart' as db;
import 'package:fitness_diary/core/database/daos/session_dao.dart';
import 'package:fitness_diary/core/database/daos/session_workout_dao.dart';
import 'package:fitness_diary/core/database/daos/workout_dao.dart';
import 'package:fitness_diary/features/workout/data/datasources/workout_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the v6 migration that ensures the `workouts`
/// table has an `exercise_name` column. Older on-device databases may
/// have named the column differently (`name`, `exerciseName`, `title`)
/// or omitted it entirely — both cases must be healed automatically so
/// the next `INSERT INTO workouts (exercise_name) VALUES (?)` succeeds.
void main() {
  group('v6 migration: ensure workouts.exercise_name column', () {
    test('fresh install already has exercise_name — no-op', () async {
      final database = db.AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      // Database was just created via createAll(); exercise_name column exists.
      final hasColumn = await _hasColumn(database, 'exercise_name');
      expect(hasColumn, isTrue);
    });

    test('legacy schema with name column gets renamed', () async {
      final database = db.AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      // Rebuild the workouts table with the 'name' column (v5 shape).
      await database.customStatement('DROP TABLE workouts');
      await database.customStatement(
        'CREATE TABLE workouts ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'name TEXT NOT NULL DEFAULT \'\', '
        'description TEXT NOT NULL DEFAULT \'\', '
        'created_at INTEGER NOT NULL DEFAULT 0)',
      );
      await database.customStatement(
        'INSERT INTO workouts (name, created_at) '
        "VALUES ('Bench Press', 1700000000)",
      );

      // Pre-condition: no `exercise_name` column, `name` exists.
      final before = await database
          .customSelect('PRAGMA table_info(workouts)')
          .get();
      final beforeNames = {for (final r in before) (r.data['name'] as String)};
      expect(beforeNames, contains('name'));
      expect(beforeNames, isNot(contains('exercise_name')));

      // Apply the same ALTER TABLE the migration uses.
      await database.customStatement(
        'ALTER TABLE workouts RENAME COLUMN name TO exercise_name',
      );

      final after = await database
          .customSelect('PRAGMA table_info(workouts)')
          .get();
      final afterNames = {for (final r in after) (r.data['name'] as String)};
      expect(afterNames, contains('exercise_name'));
      expect(afterNames, isNot(contains('name')));

      // The data is preserved.
      final rows = await database
          .customSelect('SELECT exercise_name FROM workouts')
          .get();
      expect(rows.length, 1);
      expect(rows.first.data['exercise_name'], 'Bench Press');
    });

    test('missing column gets added with default', () async {
      final database = db.AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      // Rebuild without any name-like column.
      await database.customStatement('DROP TABLE workouts');
      await database.customStatement(
        'CREATE TABLE workouts ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'description TEXT NOT NULL DEFAULT \'\', '
        'created_at INTEGER NOT NULL DEFAULT 0)',
      );

      // Confirm there's no exercise_name column.
      final before = await database
          .customSelect('PRAGMA table_info(workouts)')
          .get();
      final beforeNames = {for (final r in before) (r.data['name'] as String)};
      expect(beforeNames, isNot(contains('exercise_name')));

      // Apply the same ALTER TABLE the migration uses.
      await database.customStatement(
        "ALTER TABLE workouts ADD COLUMN exercise_name TEXT NOT NULL DEFAULT ''",
      );

      final after = await database
          .customSelect('PRAGMA table_info(workouts)')
          .get();
      final afterNames = {for (final r in after) (r.data['name'] as String)};
      expect(afterNames, contains('exercise_name'));
    });
  });

  group('end-to-end insert after the migration', () {
    test('insert into a database with a migrated column succeeds', () async {
      final database = db.AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      // Start with 'name' (v5).
      await database.customStatement('DROP TABLE workouts');
      await database.customStatement(
        'CREATE TABLE workouts ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'name TEXT NOT NULL DEFAULT \'\', '
        'description TEXT NOT NULL DEFAULT \'\', '
        'created_at INTEGER NOT NULL DEFAULT 0)',
      );

      // Apply the v6 rename.
      await database.customStatement(
        'ALTER TABLE workouts RENAME COLUMN name TO exercise_name',
      );

      // Apply the v8 addition (is_favorite) so the e2e insert below
      // runs against the current schema.
      await database.customStatement(
        'ALTER TABLE workouts ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
      );

      // Seed a session.
      await SessionDao(
        database,
      ).insertSession(db.SessionsCompanion.insert(name: 'Leg Day'));

      final ds = WorkoutLocalDataSource(
        database: database,
        sessionWorkoutDao: SessionWorkoutDao(database),
        workoutDao: WorkoutDao(database),
        sessionDao: SessionDao(database),
      );

      // Insert must succeed with the new column name.
      final result = await ds.insert(
        sessionId: 1,
        exerciseName: 'Bench Press',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 60.0,
        notes: '',
      );
      expect(result.id, isNotNull);

      final allWorkouts = await WorkoutDao(database).getAllWorkouts();
      expect(allWorkouts.map((w) => w.exerciseName), contains('Bench Press'));
    });
  });
}

Future<bool> _hasColumn(db.AppDatabase db, String column) async {
  final rows = await db
      .customSelect('PRAGMA table_info(workouts)', readsFrom: {db.workouts})
      .get();
  final names = {for (final r in rows) (r.data['name'] as String)};
  return names.contains(column);
}
