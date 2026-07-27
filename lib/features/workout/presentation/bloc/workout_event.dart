import 'package:equatable/equatable.dart';

abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorkouts extends WorkoutEvent {
  const LoadWorkouts();
}

class LoadWorkoutsBySession extends WorkoutEvent {
  const LoadWorkoutsBySession(this.sessionId);

  final int sessionId;

  @override
  List<Object?> get props => [sessionId];
}

class AddWorkout extends WorkoutEvent {
  const AddWorkout({
    required this.sessionId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  final int sessionId;
  final String exerciseName;
  final int sets;
  final int reps;
  final double weight;

  @override
  List<Object?> get props => [sessionId, exerciseName, sets, reps, weight];
}

class DeleteWorkout extends WorkoutEvent {
  const DeleteWorkout(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
