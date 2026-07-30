import 'package:drift/native.dart';
import 'package:fitness_diary/core/database/app_database.dart' as db;
import 'package:fitness_diary/core/database/daos/session_dao.dart';
import 'package:fitness_diary/core/database/daos/session_workout_dao.dart';
import 'package:fitness_diary/core/database/daos/workout_dao.dart';
import 'package:fitness_diary/features/workout/data/datasources/workout_local_datasource.dart';
import 'package:fitness_diary/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:fitness_diary/features/workout/domain/usecases/add_workout.dart';
import 'package:fitness_diary/features/workout/domain/usecases/delete_workout.dart';
import 'package:fitness_diary/features/workout/domain/usecases/reorder_workouts.dart';
import 'package:fitness_diary/features/workout/domain/usecases/update_workout.dart';
import 'package:fitness_diary/features/workout/domain/usecases/watch_workouts.dart';
import 'package:fitness_diary/features/workout/presentation/bloc/workout_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end reproduction of the user's reported issue: opening the
/// Today page → picking session 1 → tapping "+ Add Workout" → filling
/// the form → pressing save → seeing an error.
void main() {
  late db.AppDatabase database;
  late WorkoutLocalDataSource ds;
  late WorkoutRepositoryImpl repo;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    ds = WorkoutLocalDataSource(
      database: database,
      sessionWorkoutDao: SessionWorkoutDao(database),
      workoutDao: WorkoutDao(database),
      sessionDao: SessionDao(database),
    );
    repo = WorkoutRepositoryImpl(dataSource: ds);
  });

  tearDown(() async {
    await database.close();
  });

  test('full bloc flow: watch → add succeeds', () async {
    // Seed a session to match the user's situation.
    await SessionDao(
      database,
    ).insertSession(db.SessionsCompanion.insert(name: 'Push Day'));

    final bloc = WorkoutListBloc(
      watchWorkouts: WatchWorkoutsForSession(repository: repo),
      addWorkout: AddWorkoutToSession(repository: repo),
      updateWorkout: UpdateWorkout(repository: repo),
      deleteWorkout: DeleteWorkout(repository: repo),
      reorderWorkouts: ReorderWorkouts(repository: repo),
    );

    final states = <WorkoutListState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const WatchWorkoutsEvent(1));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    bloc.add(
      const AddWorkoutEvent(
        sessionId: 1,
        exerciseName: 'Bench Press',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 60.0,
        notes: '',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));

    await sub.cancel();
    await bloc.close();

    final errors = states.whereType<WorkoutListError>().toList();
    expect(errors, isEmpty, reason: 'bloc emitted WorkoutListError after save');
  });

  test('full bloc flow: watch → two adds in a row', () async {
    await SessionDao(
      database,
    ).insertSession(db.SessionsCompanion.insert(name: 'Push Day'));

    final bloc = WorkoutListBloc(
      watchWorkouts: WatchWorkoutsForSession(repository: repo),
      addWorkout: AddWorkoutToSession(repository: repo),
      updateWorkout: UpdateWorkout(repository: repo),
      deleteWorkout: DeleteWorkout(repository: repo),
      reorderWorkouts: ReorderWorkouts(repository: repo),
    );

    final states = <WorkoutListState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const WatchWorkoutsEvent(1));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    bloc.add(
      const AddWorkoutEvent(
        sessionId: 1,
        exerciseName: 'Bench Press',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 60.0,
        notes: '',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));

    bloc.add(
      const AddWorkoutEvent(
        sessionId: 1,
        exerciseName: 'Incline Press',
        defaultSets: 3,
        defaultReps: 10,
        defaultWeight: 50.0,
        notes: '',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));

    await sub.cancel();
    await bloc.close();

    final errors = states.whereType<WorkoutListError>().toList();
    expect(
      errors,
      isEmpty,
      reason:
          'second add emitted error: ${errors.map((e) => e.failure.message).join(', ')}',
    );

    final loaded = states.whereType<WorkoutListLoaded>().toList();
    expect(loaded, isNotEmpty);
    expect(loaded.last.workouts, hasLength(2));
  });
}
