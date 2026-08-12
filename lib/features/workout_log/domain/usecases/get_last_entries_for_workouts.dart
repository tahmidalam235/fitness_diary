import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/workout_log_entry.dart';
import '../repositories/workout_log_repository.dart';

/// Returns the most recent prior entry (strictly before today) per
/// master workout id. Used by the prefill flow when a workout is added
/// to today's session — the new entry is seeded with yesterday's
/// values so the user can edit instead of starting from scratch.
class GetLastEntriesForWorkouts
    extends UseCase<Map<int, WorkoutLogEntry>, List<int>> {
  const GetLastEntriesForWorkouts({required this.repository});

  final WorkoutLogRepository repository;

  @override
  Future<Either<Failure, Map<int, WorkoutLogEntry>>> call(List<int> params) {
    return repository.getLastEntriesForWorkouts(params);
  }
}
