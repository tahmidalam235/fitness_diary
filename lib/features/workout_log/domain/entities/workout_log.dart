import 'package:equatable/equatable.dart';

/// A workout day — one [WorkoutLog] per (session, day) pair.
class WorkoutLog extends Equatable {
  const WorkoutLog({
    required this.id,
    required this.sessionId,
    required this.performedAt,
  });

  final int id;
  final int sessionId;
  final DateTime performedAt;

  @override
  List<Object?> get props => [id, sessionId, performedAt];
}
