import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import '../../domain/repositories/history_repository.dart';

/// Streams every [WorkoutLogEntry] for every log performed on the given
/// calendar day, grouped by `WorkoutLog.id`.
class WatchEntriesByLogForDay
    extends StreamUseCase<Map<int, List<WorkoutLogEntry>>, DateTime> {
  const WatchEntriesByLogForDay({required this.repository});

  final HistoryRepository repository;

  @override
  Stream<Either<Failure, Map<int, List<WorkoutLogEntry>>>> call(
    DateTime params,
  ) {
    return repository.watchEntriesByLogForDay(params);
  }
}