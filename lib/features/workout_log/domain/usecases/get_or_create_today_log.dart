import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/workout_log.dart';
import '../repositories/workout_log_repository.dart';

class GetOrCreateTodayLog extends UseCase<WorkoutLog, int> {
  const GetOrCreateTodayLog({required this.repository});

  final WorkoutLogRepository repository;

  @override
  Future<Either<Failure, WorkoutLog>> call(int params) {
    return repository.getOrCreateTodayLog(params);
  }
}
