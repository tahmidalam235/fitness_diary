import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../repositories/workout_log_repository.dart';

class DeleteEntry extends UseCase<Unit, int> {
  const DeleteEntry({required this.repository});

  final WorkoutLogRepository repository;

  @override
  Future<Either<Failure, Unit>> call(int params) {
    return repository.deleteEntry(params);
  }
}
