import '../../domain/entities/body_part.dart';
import '../../domain/entities/workout.dart';

/// JSON adapter for [Workout].
///
/// Source of truth lives in Firestore: every [WorkoutModel] carries
/// both `firestoreId` / `masterFirestoreId` (the Firestore document
/// ids, source of truth) and `id` / `workoutId` (ints derived from
/// `firestoreId.hashCode` for backwards-compat with the int-keyed
/// domain layer).
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
    this.targetedBodyPart,
    this.firestoreId,
    this.masterFirestoreId,
    this.sessionFirestoreId,
    this.createdAt,
    this.updatedAt,
  });

  /// Builds a [WorkoutModel] from a Firestore document. The local int
  /// `id` / `workoutId` / `sessionId` are derived from the
  /// corresponding firestoreId hashes.
  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    final joinFid = json['firestoreId'] as String;
    final masterFid = json['masterFirestoreId'] as String;
    final sessionFid = json['sessionFirestoreId'] as String?;
    return WorkoutModel(
      id: joinFid.hashCode,
      sessionId: sessionFid?.hashCode ?? 0,
      workoutId: masterFid.hashCode,
      exerciseName: json['exerciseName'] as String,
      position: json['position'] as int,
      defaultSets: json['defaultSets'] as int,
      defaultReps: json['defaultReps'] as int,
      defaultDurationSeconds: json['defaultDurationSeconds'] as int?,
      defaultWeight: (json['defaultWeight'] as num?)?.toDouble(),
      notes: (json['notes'] as String?) ?? '',
      targetedBodyPart: BodyPart.fromId(json['targetedBodyPart'] as String?),
      firestoreId: joinFid,
      masterFirestoreId: masterFid,
      sessionFirestoreId: sessionFid,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
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
  final BodyPart? targetedBodyPart;
  final String? firestoreId;
  final String? masterFirestoreId;
  final String? sessionFirestoreId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
      targetedBodyPart: targetedBodyPart,
      masterFirestoreId: masterFirestoreId,
    );
  }

  /// JSON shape for cloud sync.
  Map<String, dynamic> toJson() => {
    'firestoreId': firestoreId,
    'masterFirestoreId': masterFirestoreId,
    'sessionFirestoreId': sessionFirestoreId,
    'exerciseName': exerciseName,
    'position': position,
    'defaultSets': defaultSets,
    'defaultReps': defaultReps,
    'defaultDurationSeconds': defaultDurationSeconds,
    'defaultWeight': defaultWeight,
    'notes': notes,
    'targetedBodyPart': targetedBodyPart?.id,
    'createdAt': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
  };
}