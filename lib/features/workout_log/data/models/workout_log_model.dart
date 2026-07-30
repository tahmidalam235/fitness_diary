import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/workout_log.dart';

class WorkoutLogModel {
  const WorkoutLogModel({
    required this.id,
    required this.sessionId,
    required this.performedAt,
  });

  factory WorkoutLogModel.fromDrift(db.WorkoutLog row) {
    return WorkoutLogModel(
      id: row.id,
      sessionId: row.sessionId,
      performedAt: row.performedAt,
    );
  }

  final int id;
  final int sessionId;
  final DateTime performedAt;

  WorkoutLog toEntity() =>
      WorkoutLog(id: id, sessionId: sessionId, performedAt: performedAt);
}
