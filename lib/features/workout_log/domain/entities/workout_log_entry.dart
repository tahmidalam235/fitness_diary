import 'package:equatable/equatable.dart';

/// Domain entity for a single workout's daily record.
///
/// After the v7 schema change there is exactly **one** [WorkoutLogEntry]
/// per `(workoutLogId, workoutId)` per day — the entry carries the
/// user's logged `sets`, `reps`, `weight`, and `duration` for that
/// workout. `setIndex`/`position` are kept on the entity only because
/// they still exist on the DB row; they always read as `1` / `0`.
class WorkoutLogEntry extends Equatable {
  const WorkoutLogEntry({
    required this.id,
    required this.workoutLogId,
    required this.workoutId,
    required this.setIndex,
    required this.position,
    this.sets,
    this.reps,
    this.weight,
    this.durationSeconds,
    this.restSeconds,
    this.notes = '',
  });

  /// Primary key. `0` indicates a not-yet-persisted row.
  final int id;

  /// Parent workout log (one per session per day).
  final int workoutLogId;

  /// Master workout id.
  final int workoutId;

  /// Always `1` — kept for backwards compatibility with the v3 schema.
  final int setIndex;

  /// Always `0` — kept for backwards compatibility with the v3 schema.
  final int position;

  /// Number of sets completed today.
  final int? sets;

  final int? reps;
  final double? weight;
  final int? durationSeconds;
  final int? restSeconds;
  final String notes;

  WorkoutLogEntry copyWith({
    int? id,
    int? workoutLogId,
    int? workoutId,
    int? setIndex,
    int? position,
    int? sets,
    int? reps,
    double? weight,
    int? durationSeconds,
    int? restSeconds,
    String? notes,
  }) {
    return WorkoutLogEntry(
      id: id ?? this.id,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      workoutId: workoutId ?? this.workoutId,
      setIndex: setIndex ?? this.setIndex,
      position: position ?? this.position,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workoutLogId,
        workoutId,
        setIndex,
        position,
        sets,
        reps,
        weight,
        durationSeconds,
        restSeconds,
        notes,
      ];
}
