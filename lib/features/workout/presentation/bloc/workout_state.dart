import '../../../../core/database/app_database.dart';

class WorkoutState {
  const WorkoutState({this.workouts = const [], this.isLoading = false});

  final List<Workout> workouts;
  final bool isLoading;

  WorkoutState copyWith({List<Workout>? workouts, bool? isLoading}) {
    return WorkoutState(
      workouts: workouts ?? this.workouts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
