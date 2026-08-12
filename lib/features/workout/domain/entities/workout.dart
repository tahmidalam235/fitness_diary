import 'package:equatable/equatable.dart';

import 'body_part.dart';

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
    this.targetedBodyPart,
    this.masterFirestoreId,
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

  /// Optional muscle group this exercise targets (Biceps, Triceps,
  /// Upper Chest, ...). `null` means no selection — older workouts
  /// that predate this feature read back as `null` and the card
  /// simply omits the body-part chip.
  final BodyPart? targetedBodyPart;

  /// Firestore document id of the master [Workouts] row this session
  /// workout was joined from. Used to stamp `WorkoutLogEntry`
  /// `workoutFirestoreId` so the entries stream can recover the entry
  /// after a round-trip — without it the seed row is dropped by the
  /// data source filter and the today page never shows the picked
  /// workout.
  final String? masterFirestoreId;

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
    BodyPart? targetedBodyPart,
    String? masterFirestoreId,
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
      targetedBodyPart: targetedBodyPart ?? this.targetedBodyPart,
      masterFirestoreId: masterFirestoreId ?? this.masterFirestoreId,
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
    targetedBodyPart,
    masterFirestoreId,
  ];
}
