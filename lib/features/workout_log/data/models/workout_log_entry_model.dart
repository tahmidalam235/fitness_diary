import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/workout_log_entry.dart';

class WorkoutLogEntryModel {
  const WorkoutLogEntryModel({
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

  factory WorkoutLogEntryModel.fromDrift(db.WorkoutLogEntry row) {
    return WorkoutLogEntryModel(
      id: row.id,
      workoutLogId: row.workoutLogId,
      workoutId: row.workoutId,
      setIndex: row.setIndex,
      position: row.position,
      sets: row.sets,
      reps: row.reps,
      weight: row.weight,
      durationSeconds: row.durationSeconds,
      restSeconds: row.restSeconds,
      notes: row.notes,
    );
  }

  final int id;
  final int workoutLogId;
  final int workoutId;
  final int setIndex;
  final int position;
  final int? sets;
  final int? reps;
  final double? weight;
  final int? durationSeconds;
  final int? restSeconds;
  final String notes;

  WorkoutLogEntryModel copyWith({
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
    return WorkoutLogEntryModel(
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

  WorkoutLogEntry toEntity() => WorkoutLogEntry(
        id: id,
        workoutLogId: workoutLogId,
        workoutId: workoutId,
        setIndex: setIndex,
        position: position,
        sets: sets,
        reps: reps,
        weight: weight,
        durationSeconds: durationSeconds,
        restSeconds: restSeconds,
        notes: notes,
      );

  db.WorkoutLogEntry toDrift() => db.WorkoutLogEntry(
        id: id,
        workoutLogId: workoutLogId,
        workoutId: workoutId,
        setIndex: setIndex,
        position: position,
        sets: sets,
        reps: reps,
        weight: weight,
        durationSeconds: durationSeconds,
        restSeconds: restSeconds,
        notes: notes,
        createdAt: DateTime.now(),
      );

  db.WorkoutLogEntriesCompanion toInsertCompanion() {
    return db.WorkoutLogEntriesCompanion.insert(
      workoutLogId: workoutLogId,
      workoutId: workoutId,
      setIndex: setIndex,
      position: position,
      sets: Value(sets),
      reps: Value(reps),
      weight: Value(weight),
      durationSeconds: Value(durationSeconds),
      restSeconds: Value(restSeconds),
      notes: Value(notes),
    );
  }
}
