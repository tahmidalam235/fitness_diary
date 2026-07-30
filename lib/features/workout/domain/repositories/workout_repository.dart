import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../entities/workout.dart';

abstract class WorkoutRepository {
  /// Streams workouts attached to [sessionId] ordered by position.
  Stream<Either<Failure, List<Workout>>> watchWorkoutsForSession(int sessionId);

  /// Creates a new master workout + session_workouts link.
  ///
  /// Returns the resulting [Workout] (with assigned id + position).
  Future<Either<Failure, Workout>> addWorkoutToSession({
    required int sessionId,
    required String exerciseName,
    required int defaultSets,
    required int defaultReps,
    int? defaultDurationSeconds,
    double? defaultWeight,
    String notes,
  });

  /// Updates the per-session defaults (and the master workout name).
  Future<Either<Failure, Workout>> updateWorkout({
    required int id,
    required String exerciseName,
    required int defaultSets,
    required int defaultReps,
    int? defaultDurationSeconds,
    double? defaultWeight,
    String notes,
  });

  /// Removes the link between the session and the workout, and the
  /// master workout if no other session references it.
  Future<Either<Failure, Unit>> deleteWorkout(int id);

  /// Persists a new manual ordering for the session's workouts.
  Future<Either<Failure, Unit>> reorderWorkouts({
    required int sessionId,
    required List<int> orderedIds,
  });
}
