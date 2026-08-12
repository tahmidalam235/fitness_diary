import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../domain/repositories/history_repository.dart';

/// Streams every [WorkoutLog] performed on the given calendar [day].
class WatchLogsForDay extends StreamUseCase<List<WorkoutLog>, DateTime> {
  const WatchLogsForDay({required this.repository});

  final HistoryRepository repository;

  @override
  Stream<Either<Failure, List<WorkoutLog>>> call(DateTime params) {
    return repository.watchLogsForDay(params);
  }
}
