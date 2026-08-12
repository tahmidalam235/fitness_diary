import '../../domain/entities/session.dart';

/// JSON adapter for [Session].
///
/// Source of truth lives in Firestore: every [SessionModel] carries a
/// `firestoreId` (the Firestore document id) and an `id` (an
/// `int` derived from `firestoreId.hashCode`) so the existing
/// int-keyed domain layer doesn't have to change.
class SessionModel {
  const SessionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.workoutCount,
    this.firestoreId,
  });

  /// Builds a [SessionModel] from a Firestore document. The local int
  /// `id` is derived from `firestoreId.hashCode` for backwards-compat
  /// with the int-keyed domain layer.
  factory SessionModel.fromJson(Map<String, dynamic> json) {
    final fid = json['firestoreId'] as String;
    return SessionModel(
      id: fid.hashCode,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
      workoutCount: 0,
      firestoreId: fid,
    );
  }

  final int? id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int workoutCount;
  final String? firestoreId;

  Session toEntity() {
    return Session(
      id: id,
      name: name,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
      workoutCount: workoutCount,
    );
  }

  /// JSON shape for cloud sync.
  Map<String, dynamic> toJson() => {
    'firestoreId': firestoreId,
    'name': name,
    'description': description,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
  };
}