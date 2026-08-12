import 'package:equatable/equatable.dart';

/// A workout day — one [WorkoutLog] per (session, day) pair.
class WorkoutLog extends Equatable {
  const WorkoutLog({
    required this.id,
    required this.sessionId,
    required this.performedAt,
    this.firestoreId,
  });

  final int id;
  final int sessionId;
  final DateTime performedAt;

  /// Stable Firestore ID of this log.
  final String? firestoreId;

  @override
  List<Object?> get props => [id, sessionId, performedAt, firestoreId];
}
