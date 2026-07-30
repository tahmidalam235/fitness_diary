import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/workout.dart';

/// Maps between Drift rows and the [Workout] domain entity.
///
/// Combines a master [db.Workout] row with its per-session
/// [db.SessionWorkout] join row so the UI can read everything from a
/// single entity.
class WorkoutModel {
  const WorkoutModel({
    required this.id,
    required this.sessionId,
    required this.workoutId,
    required this.exerciseName,
    required this.position,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultDurationSeconds,
    required this.defaultWeight,
    required this.notes,
  });

  factory WorkoutModel.fromJoin(db.Workout master, db.SessionWorkout join) {
    return WorkoutModel(
      id: join.id,
      sessionId: join.sessionId,
      workoutId: join.workoutId,
      exerciseName: master.exerciseName,
      position: join.position,
      defaultSets: join.defaultSets,
      defaultReps: join.defaultReps,
      defaultDurationSeconds: join.defaultDurationSeconds,
      defaultWeight: join.defaultWeight,
      notes: join.notes,
    );
  }

  /// Builds a [WorkoutModel] from only the master workout row. Used by the
  /// history path where we need the master workout's name but don't have
  /// a join row in scope. Join-only fields default to safe placeholders.
  factory WorkoutModel.fromMaster(db.Workout master) {
    return WorkoutModel(
      id: master.id,
      sessionId: 0,
      workoutId: master.id,
      exerciseName: master.exerciseName,
      position: 0,
      defaultSets: 0,
      defaultReps: 0,
      defaultDurationSeconds: null,
      defaultWeight: null,
      notes: '',
    );
  }

  final int id;
  final int sessionId;
  final int workoutId;
  final String exerciseName;
  final int position;
  final int defaultSets;
  final int defaultReps;
  final int? defaultDurationSeconds;
  final double? defaultWeight;
  final String notes;

  Workout toEntity() {
    return Workout(
      id: id,
      sessionId: sessionId,
      workoutId: workoutId,
      exerciseName: exerciseName,
      position: position,
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      defaultDurationSeconds: defaultDurationSeconds,
      defaultWeight: defaultWeight,
      notes: notes,
    );
  }
}
