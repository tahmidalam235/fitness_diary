import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import '../repositories/history_repository.dart';
import 'watch_logs_in_range.dart'; // for DateRange

/// Streams every [WorkoutLogEntry] whose parent log was performed in
/// the half-open range `[start, end)`.
class WatchEntriesInRange
    extends StreamUseCase<List<WorkoutLogEntry>, DateRange> {
  const WatchEntriesInRange({required this.repository});

  final HistoryRepository repository;

  @override
  Stream<Either<Failure, List<WorkoutLogEntry>>> call(DateRange params) {
    return repository.watchEntriesInRange(start: params.start, end: params.end);
  }
}
