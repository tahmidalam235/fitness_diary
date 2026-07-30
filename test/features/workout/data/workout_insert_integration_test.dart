import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:fitness_diary/core/database/app_database.dart' as db;
import 'package:fitness_diary/core/database/daos/session_dao.dart';
import 'package:fitness_diary/core/database/daos/session_workout_dao.dart';
import 'package:fitness_diary/core/database/daos/workout_dao.dart';
import 'package:fitness_diary/features/workout/data/datasources/workout_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late WorkoutLocalDataSource ds;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    ds = WorkoutLocalDataSource(
      database: database,
      sessionWorkoutDao: SessionWorkoutDao(database),
      workoutDao: WorkoutDao(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('insert a workout into a fresh session', () async {
    final sessionId = await SessionDao(database).insertSession(
      db.SessionsCompanion.insert(
        name: 'Push Day',
        description: const drift.Value(''),
      ),
    );

    final result = await ds.insert(
      sessionId: sessionId,
      exerciseName: 'Bench Press',
      defaultSets: 3,
      defaultReps: 10,
      defaultDurationSeconds: null,
      defaultWeight: 60.0,
      notes: '',
    );
    expect(result.id, isNotNull);
  });

  test('insert two workouts into the same session', () async {
    final sessionId = await SessionDao(
      database,
    ).insertSession(db.SessionsCompanion.insert(name: 'Push Day'));

    final first = await ds.insert(
      sessionId: sessionId,
      exerciseName: 'Bench Press',
      defaultSets: 3,
      defaultReps: 10,
      defaultWeight: 60.0,
      notes: '',
    );
    final second = await ds.insert(
      sessionId: sessionId,
      exerciseName: 'Incline Press',
      defaultSets: 3,
      defaultReps: 10,
      defaultWeight: 50.0,
      notes: '',
    );
    expect(first.id, isNotNull);
    expect(second.id, isNotNull);
    expect(first.id, isNot(equals(second.id)));
  });

  test('insert with explicit session id 1 via DAO', () async {
    final sessionId = await SessionDao(
      database,
    ).insertSession(db.SessionsCompanion.insert(name: 'Push Day'));
    expect(sessionId, 1);
    final result = await ds.insert(
      sessionId: sessionId,
      exerciseName: 'Bench Press',
      defaultSets: 3,
      defaultReps: 10,
      defaultWeight: 60.0,
      notes: '',
    );
    expect(result.id, isNotNull);
  });

  test('regression: session with stale master workout row '
      '(previously orphaned by interrupted insert) still allows add', () async {
    final sessionId = await SessionDao(
      database,
    ).insertSession(db.SessionsCompanion.insert(name: 'Push Day'));
    // Simulate the previously broken state: an orphaned master `Workouts`
    // row exists (no matching `session_workouts` row) because an earlier
    // interrupted insert left it behind. The (sessionId, workoutId)
    // unique constraint must NOT trigger for a fresh master row, and a
    // second insert should still succeed cleanly.
    await database.customStatement(
      "INSERT INTO workouts (id, exercise_name) VALUES (777, 'Ghost Workout')",
    );
    final first = await ds.insert(
      sessionId: sessionId,
      exerciseName: 'Bench Press',
      defaultSets: 3,
      defaultReps: 10,
      defaultWeight: 60.0,
      notes: '',
    );
    expect(first.id, isNotNull);
    final second = await ds.insert(
      sessionId: sessionId,
      exerciseName: 'Incline Press',
      defaultSets: 3,
      defaultReps: 10,
      defaultWeight: 50.0,
      notes: '',
    );
    expect(second.id, isNotNull);
  });

  test(
    'throws NotFoundException when inserting into a missing session',
    () async {
      expect(
        () => ds.insert(
          sessionId: 9999,
          exerciseName: 'Bench Press',
          defaultSets: 3,
          defaultReps: 10,
          defaultWeight: 60.0,
          notes: '',
        ),
        throwsA(isA<Exception>()),
      );
    },
  );
}
