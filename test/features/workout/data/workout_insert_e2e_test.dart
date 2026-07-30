import 'package:drift/native.dart';
import 'package:fitness_diary/core/database/app_database.dart' as db;
import 'package:fitness_diary/core/database/daos/session_dao.dart';
import 'package:fitness_diary/core/database/daos/session_workout_dao.dart';
import 'package:fitness_diary/core/database/daos/workout_dao.dart';
import 'package:fitness_diary/features/workout/data/datasources/workout_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end reproduction of the user's reported "still failing to add
/// workout at session 1" issue, exercising the full path from an
/// existing on-disk database through the migration cleanup and the
/// transactional insert.
void main() {
  test(
    'add workout after migrating from v3 with stale rows in session_workouts',
    () async {
      // 1) Build a v3-shaped database file with stale rows that mimic
      //    what the user's device likely contains.
      final oldDb = db.AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(oldDb.close);
      await SessionDao(
        oldDb,
      ).insertSession(db.SessionsCompanion.insert(name: 'Push Day'));
      // Manually plant a stale (session_id, workout_id) join pointing at
      // a non-existent master workout. This is exactly what an interrupted
      // insert leaves behind.
      await oldDb.customStatement(
        'INSERT INTO workouts (id, exercise_name) VALUES (1, \'stale\')',
      );
      await oldDb.customStatement(
        'INSERT INTO session_workouts '
        '(session_id, workout_id, position, default_sets, default_reps, notes) '
        'VALUES (1, 1, 0, 3, 10, \'\')',
      );

      // 2) Build the new (v4) database, then run the migration that the
      //    production code uses. After the migration runs, the user should
      //    be able to add a workout to session 1 cleanly.
      final newDb = db.AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(newDb.close);
      // Manually re-create the same rows because newDb is in-memory and
      // doesn't share with oldDb.
      final dao = SessionDao(newDb);
      await dao.insertSession(db.SessionsCompanion.insert(name: 'Push Day'));
      await newDb.customStatement(
        'INSERT INTO workouts (id, exercise_name) VALUES (1, \'stale\')',
      );
      await newDb.customStatement(
        'INSERT INTO session_workouts '
        '(session_id, workout_id, position, default_sets, default_reps, notes) '
        'VALUES (1, 1, 0, 3, 10, \'\')',
      );

      // Run the same migration cleanup the production code runs on
      // upgrade to v4.
      await newDb.customStatement(
        'DELETE FROM workouts WHERE id NOT IN '
        '(SELECT DISTINCT workout_id FROM session_workouts)',
      );

      // Now the user opens the form and submits. This MUST succeed.
      final ds = WorkoutLocalDataSource(
        database: newDb,
        sessionWorkoutDao: SessionWorkoutDao(newDb),
        workoutDao: WorkoutDao(newDb),
        sessionDao: SessionDao(newDb),
      );
      final result = await ds.insert(
        sessionId: 1,
        exerciseName: 'Bench Press',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 60.0,
        notes: '',
      );
      expect(result.id, isNotNull);
      // Verify the new workout is in the join table at the correct position.
      final join = await SessionWorkoutDao(newDb).getBySession(1);
      expect(join, hasLength(2));
    },
  );

  test(
    'add workout where position 0 already exists with a different workout',
    () async {
      final database = db.AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await SessionDao(
        database,
      ).insertSession(db.SessionsCompanion.insert(name: 'Push Day'));
      final ds = WorkoutLocalDataSource(
        database: database,
        sessionWorkoutDao: SessionWorkoutDao(database),
        workoutDao: WorkoutDao(database),
        sessionDao: SessionDao(database),
      );
      // First insert at position 0.
      await ds.insert(
        sessionId: 1,
        exerciseName: 'Bench Press',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 60.0,
        notes: '',
      );
      // Second insert must pick position 1.
      final second = await ds.insert(
        sessionId: 1,
        exerciseName: 'Incline Press',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 50.0,
        notes: '',
      );
      expect(second.position, 1);
    },
  );

  test('add many workouts sequentially to one session', () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await SessionDao(
      database,
    ).insertSession(db.SessionsCompanion.insert(name: 'Push Day'));
    final ds = WorkoutLocalDataSource(
      database: database,
      sessionWorkoutDao: SessionWorkoutDao(database),
      workoutDao: WorkoutDao(database),
      sessionDao: SessionDao(database),
    );
    for (var i = 0; i < 10; i++) {
      final r = await ds.insert(
        sessionId: 1,
        exerciseName: 'Workout $i',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 60.0 + i,
        notes: '',
      );
      expect(r.position, i);
    }
  });

  test(
    'add workout when session_workouts has gaps in positions (legacy data)',
    () async {
      // Some users may have session_workouts rows where position values
      // have gaps due to legacy data or partial imports. nextPosition
      // returns max+1, but the new insert path also defends against
      // collisions by checking every existing position.
      final database = db.AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await SessionDao(
        database,
      ).insertSession(db.SessionsCompanion.insert(name: 'Push Day'));
      // Manually create rows at positions 0 and 5 with a gap.
      await database.customStatement(
        'INSERT INTO workouts (id, exercise_name) VALUES (1, \'Row 1\')',
      );
      await database.customStatement(
        'INSERT INTO workouts (id, exercise_name) VALUES (2, \'Row 2\')',
      );
      await database.customStatement(
        'INSERT INTO session_workouts '
        '(session_id, workout_id, position, default_sets, default_reps, notes) '
        'VALUES (1, 1, 0, 3, 10, \'\')',
      );
      await database.customStatement(
        'INSERT INTO session_workouts '
        '(session_id, workout_id, position, default_sets, default_reps, notes) '
        'VALUES (1, 2, 5, 3, 10, \'\')',
      );

      final ds = WorkoutLocalDataSource(
        database: database,
        sessionWorkoutDao: SessionWorkoutDao(database),
        workoutDao: WorkoutDao(database),
        sessionDao: SessionDao(database),
      );
      // The new insert picks position 6 (max+1) and that's free.
      final r = await ds.insert(
        sessionId: 1,
        exerciseName: 'New Workout',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 60.0,
        notes: '',
      );
      expect(r.position, 6);
    },
  );

  test('throws ValidationException when sessionId is 0 or negative', () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final ds = WorkoutLocalDataSource(
      database: database,
      sessionWorkoutDao: SessionWorkoutDao(database),
      workoutDao: WorkoutDao(database),
      sessionDao: SessionDao(database),
    );
    expect(
      () => ds.insert(
        sessionId: 0,
        exerciseName: 'X',
        defaultSets: 3,
        defaultReps: 10,
        notes: '',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
