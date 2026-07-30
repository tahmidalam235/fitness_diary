import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/workout_log_entry.dart';
import '../repositories/workout_log_repository.dart';

class UpsertEntry extends UseCase<WorkoutLogEntry, WorkoutLogEntry> {
  const UpsertEntry({required this.repository});

  final WorkoutLogRepository repository;

  @override
  Future<Either<Failure, WorkoutLogEntry>> call(WorkoutLogEntry params) {
    return repository.upsertEntry(params);
  }
}
