import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/workout_log.dart';
import '../entities/workout_log_entry.dart';
import '../repositories/workout_log_repository.dart';

/// Parameters for [AddWorkoutsToToday]. Carries the session that owns
/// today's log plus the (one-entry-per-workout) list to insert.
class AddWorkoutsToTodayParams {
  const AddWorkoutsToTodayParams({
    required this.sessionId,
    required this.entries,
  });

  final int sessionId;

  /// One [WorkoutLogEntry] per selected workout. `id` is ignored (rows
  /// are always inserted as new); `workoutLogId` is ignored (the log
  /// is created/found by the repository).
  final List<WorkoutLogEntry> entries;
}

/// Adds the supplied entries to today's workout log (creating the log
/// lazily). Used by the Session Details "Add for Today's Session"
/// action to bulk-seed today's tracked workouts.
class AddWorkoutsToToday
    extends UseCase<WorkoutLog, AddWorkoutsToTodayParams> {
  const AddWorkoutsToToday({required this.repository});

  final WorkoutLogRepository repository;

  @override
  Future<Either<Failure, WorkoutLog>> call(AddWorkoutsToTodayParams params) {
    return repository.addWorkoutsToToday(
      sessionId: params.sessionId,
      entries: params.entries,
    );
  }
}
