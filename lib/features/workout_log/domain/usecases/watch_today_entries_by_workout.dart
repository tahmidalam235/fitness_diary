import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/workout_log_entry.dart';
import '../repositories/workout_log_repository.dart';

/// Streams today's workout entries for [sessionId] keyed by master
/// workout id. There is at most one row per workout per day under the
/// v7+ single-card model, so the UI can look entries up directly.
class WatchTodayEntriesByWorkout
    extends StreamUseCase<Map<int, WorkoutLogEntry>, int> {
  const WatchTodayEntriesByWorkout({required this.repository});

  final WorkoutLogRepository repository;

  @override
  Stream<Either<Failure, Map<int, WorkoutLogEntry>>> call(int params) {
    return repository.watchTodayEntriesByWorkout(params);
  }
}
