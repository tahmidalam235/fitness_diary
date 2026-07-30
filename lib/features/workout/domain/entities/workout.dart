import 'package:equatable/equatable.dart';

/// Domain entity representing an exercise attached to a session template.
///
/// Combines master [Workout] data (name) with per-session defaults
/// pulled from [SessionWorkouts] (sets, reps, duration, weight, notes).
class Workout extends Equatable {
  const Workout({
    required this.id,
    required this.exerciseName,
    required this.position,
    required this.defaultSets,
    required this.defaultReps,
    this.defaultDurationSeconds,
    this.defaultWeight,
    this.notes = '',
    required this.sessionId,
    required this.workoutId,
  });

  /// Primary key of the [SessionWorkouts] row.
  final int id;

  /// Foreign key to the [Sessions] template row.
  final int sessionId;

  /// Foreign key to the master [Workouts] row.
  final int workoutId;

  /// Display name copied from the master workout.
  final String exerciseName;

  /// 0-based ordering inside the session.
  final int position;

  /// Default set count to seed new workout logs with.
  final int defaultSets;

  /// Default rep count per set.
  final int defaultReps;

  /// Default duration in seconds (nullable).
  final int? defaultDurationSeconds;

  /// Default starting weight (nullable).
  final double? defaultWeight;

  /// Optional notes attached to this exercise in the session.
  final String notes;

  Workout copyWith({
    int? id,
    int? sessionId,
    int? workoutId,
    String? exerciseName,
    int? position,
    int? defaultSets,
    int? defaultReps,
    int? defaultDurationSeconds,
    double? defaultWeight,
    String? notes,
  }) {
    return Workout(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      workoutId: workoutId ?? this.workoutId,
      exerciseName: exerciseName ?? this.exerciseName,
      position: position ?? this.position,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultDurationSeconds:
          defaultDurationSeconds ?? this.defaultDurationSeconds,
      defaultWeight: defaultWeight ?? this.defaultWeight,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sessionId,
    workoutId,
    exerciseName,
    position,
    defaultSets,
    defaultReps,
    defaultDurationSeconds,
    defaultWeight,
    notes,
  ];
}
