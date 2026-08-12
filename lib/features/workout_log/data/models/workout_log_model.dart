import '../../domain/entities/workout_log.dart';

/// JSON adapter for [WorkoutLog].
///
/// Source of truth lives in Firestore: every [WorkoutLogModel] carries
/// both `firestoreId` / `sessionFirestoreId` (Firestore document ids,
/// source of truth) and `id` / `sessionId` (ints derived from the
/// corresponding firestoreId hashes for backwards-compat with the
/// int-keyed domain layer).
class WorkoutLogModel {
  const WorkoutLogModel({
    required this.id,
    required this.sessionId,
    required this.performedAt,
    this.firestoreId,
    this.sessionFirestoreId,
    this.updatedAt,
  });

  /// Builds a [WorkoutLogModel] from a Firestore document. The local
  /// int `id` / `sessionId` are derived from the corresponding
  /// firestoreId hashes.
  factory WorkoutLogModel.fromJson(Map<String, dynamic> json) {
    final fid = json['firestoreId'] as String;
    final sessionFid = json['sessionFirestoreId'] as String?;
    return WorkoutLogModel(
      id: fid.hashCode,
      sessionId: sessionFid?.hashCode ?? 0,
      performedAt: DateTime.fromMillisecondsSinceEpoch(
        json['performedAt'] as int,
      ),
      firestoreId: fid,
      sessionFirestoreId: sessionFid,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
    );
  }

  final int id;
  final int sessionId;
  final DateTime performedAt;
  final String? firestoreId;
  final String? sessionFirestoreId;
  final DateTime? updatedAt;

  WorkoutLog toEntity() => WorkoutLog(
    id: id,
    sessionId: sessionId,
    performedAt: performedAt,
    firestoreId: firestoreId,
  );

  Map<String, dynamic> toJson() => {
    'firestoreId': firestoreId,
    'sessionFirestoreId': sessionFirestoreId,
    'performedAt': performedAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
  };
}
