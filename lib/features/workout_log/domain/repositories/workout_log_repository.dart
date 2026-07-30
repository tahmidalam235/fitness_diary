import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../entities/workout_log.dart';
import '../entities/workout_log_entry.dart';

/// Contract for daily workout-log persistence.
///
/// Daily tracking is **separate** from the session template. The session
/// template's master workouts and `SessionWorkouts` defaults are never
/// mutated here — only [WorkoutLogs] / [WorkoutLogEntries] are written.
abstract class WorkoutLogRepository {
  /// Returns today's log for [sessionId], creating one if none exists.
  Future<Either<Failure, WorkoutLog>> getOrCreateTodayLog(int sessionId);

  /// Watches today's entries for [sessionId] as a `Map<workoutId, entry>`.
  /// The v7+ contract guarantees exactly one row per workout per day.
  Stream<Either<Failure, Map<int, WorkoutLogEntry>>>
      watchTodayEntriesByWorkout(int sessionId);

  /// Upserts a single entry. Returns the persisted entity.
  Future<Either<Failure, WorkoutLogEntry>> upsertEntry(
    WorkoutLogEntry entry,
  );

  /// Deletes an entry by id.
  Future<Either<Failure, Unit>> deleteEntry(int id);

  /// Creates (or finds) today's log for [sessionId] and inserts one
  /// entry per element of [entries]. Returns the (now-persisted) log.
  /// Callers are responsible for not duplicating entries for the same
  /// `(workoutLogId, workoutId)` — the application layer enforces the
  /// one-row-per-workout invariant.
  Future<Either<Failure, WorkoutLog>> addWorkoutsToToday({
    required int sessionId,
    required List<WorkoutLogEntry> entries,
  });

  /// Returns the most recent prior entry (strictly before today) per
  /// workout id in [workoutIds]. Used by the prefill flow.
  Future<Either<Failure, Map<int, WorkoutLogEntry>>>
      getLastEntriesForWorkouts(List<int> workoutIds);
}
