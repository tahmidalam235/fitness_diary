import '../../domain/entities/workout_log_entry.dart';

/// JSON adapter for [WorkoutLogEntry].
///
/// Source of truth lives in Firestore: every [WorkoutLogEntryModel]
/// carries both `firestoreId` / `workoutLogFirestoreId` /
/// `workoutFirestoreId` (Firestore document ids) and `id` /
/// `workoutLogId` / `workoutId` (ints derived from the corresponding
/// firestoreId hashes for backwards-compat with the int-keyed domain
/// layer).
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
    this.firestoreId,
    this.workoutLogFirestoreId,
    this.workoutFirestoreId,
    this.createdAt,
    this.updatedAt,
  });

  /// Builds a [WorkoutLogEntryModel] from a Firestore document. Local
  /// int ids are derived from the corresponding firestoreId hashes.
  factory WorkoutLogEntryModel.fromJson(Map<String, dynamic> json) {
    final fid = json['firestoreId'] as String;
    final logFid = json['workoutLogFirestoreId'] as String?;
    final workoutFid = json['workoutFirestoreId'] as String?;
    return WorkoutLogEntryModel(
      id: fid.hashCode,
      workoutLogId: logFid?.hashCode ?? 0,
      workoutId: workoutFid?.hashCode ?? 0,
      setIndex: json['setIndex'] as int,
      position: json['position'] as int,
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      durationSeconds: json['durationSeconds'] as int?,
      restSeconds: json['restSeconds'] as int?,
      notes: (json['notes'] as String?) ?? '',
      firestoreId: fid,
      workoutLogFirestoreId: logFid,
      workoutFirestoreId: workoutFid,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
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
  final String? firestoreId;
  final String? workoutLogFirestoreId;
  final String? workoutFirestoreId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    String? firestoreId,
    String? workoutLogFirestoreId,
    String? workoutFirestoreId,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      firestoreId: firestoreId ?? this.firestoreId,
      workoutLogFirestoreId:
          workoutLogFirestoreId ?? this.workoutLogFirestoreId,
      workoutFirestoreId: workoutFirestoreId ?? this.workoutFirestoreId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    firestoreId: firestoreId,
    workoutLogFirestoreId: workoutLogFirestoreId,
    workoutFirestoreId: workoutFirestoreId,
  );

  Map<String, dynamic> toJson() => {
    'firestoreId': firestoreId,
    'workoutLogFirestoreId': workoutLogFirestoreId,
    'workoutFirestoreId': workoutFirestoreId,
    'setIndex': setIndex,
    'position': position,
    'sets': sets,
    'reps': reps,
    'weight': weight,
    'durationSeconds': durationSeconds,
    'restSeconds': restSeconds,
    'notes': notes,
    'createdAt': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
  };
}
