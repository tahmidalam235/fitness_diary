import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';

/// Read-only facade over the workout history tables.
///
/// Distinct from [WorkoutLogRepository] (which is anchored on a single
/// session for today-tracking) — this contract exposes the date-range
/// queries needed by the Calendar, Daily Details, and future Dashboard,
/// Streak, and Personal Records features.
abstract class HistoryRepository {
  /// Streams every [WorkoutLog] whose [WorkoutLog.performedAt] falls in
  /// the half-open range `[start, end)`. Used by the calendar to render
  /// per-day indicators for the visible month.
  Stream<Either<Failure, List<WorkoutLog>>> watchLogsInRange({
    required DateTime start,
    required DateTime end,
  });

  /// Streams every [WorkoutLog] performed on the given calendar [day]. A
  /// day may contain multiple logs (one per session performed).
  Stream<Either<Failure, List<WorkoutLog>>> watchLogsForDay(DateTime day);

  /// Streams every [WorkoutLogEntry] for every log performed on the given
  /// calendar [day], grouped by `WorkoutLog.id` so the UI can render one
  /// card per session.
  Stream<Either<Failure, Map<int, List<WorkoutLogEntry>>>>
  watchEntriesByLogForDay(DateTime day);

  /// Streams every [WorkoutLogEntry] whose parent log was performed in
  /// the half-open range `[start, end)`.
  Stream<Either<Failure, List<WorkoutLogEntry>>> watchEntriesInRange({
    required DateTime start,
    required DateTime end,
  });

  /// One-shot lookup of master workouts by id. Used by the Daily Details
  /// page to render exercise names without N round trips.
  Future<Either<Failure, Map<int, Workout>>> getWorkoutsByIds(
    List<int> workoutIds,
  );
}
