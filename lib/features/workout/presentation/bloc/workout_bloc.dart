import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/workout_dao.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  WorkoutBloc(this._workoutDao) : super(const WorkoutState()) {
    on<LoadWorkouts>(_onLoadWorkouts);
    on<LoadWorkoutsBySession>(_onLoadWorkoutsBySession);
    on<AddWorkout>(_onAddWorkout);
    on<DeleteWorkout>(_onDeleteWorkout);
  }

  final WorkoutDao _workoutDao;

  Future<void> _onLoadWorkouts(
    LoadWorkouts event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final workouts = await _workoutDao.getAllWorkouts();

    emit(state.copyWith(isLoading: false, workouts: workouts));
  }

  Future<void> _onLoadWorkoutsBySession(
    LoadWorkoutsBySession event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final workouts = await _workoutDao.getWorkoutsBySession(event.sessionId);

    emit(state.copyWith(isLoading: false, workouts: workouts));
  }

  Future<void> _onAddWorkout(
    AddWorkout event,
    Emitter<WorkoutState> emit,
  ) async {
    await _workoutDao.insertWorkout(
      WorkoutsCompanion.insert(
        sessionId: event.sessionId,
        exerciseName: event.exerciseName,
        sets: event.sets,
        reps: event.reps,
        weight: Value(event.weight),
      ),
    );

    add(LoadWorkoutsBySession(event.sessionId));
  }

  Future<void> _onDeleteWorkout(
    DeleteWorkout event,
    Emitter<WorkoutState> emit,
  ) async {
    final workout = state.workouts.firstWhere((e) => e.id == event.id);

    await _workoutDao.deleteWorkout(event.id);

    add(LoadWorkoutsBySession(workout.sessionId));
  }
}
