import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../repositories/workout_repository.dart';

class DeleteWorkout extends UseCase<Unit, int> {
  const DeleteWorkout({required this.repository});

  final WorkoutRepository repository;

  @override
  Future<Either<Failure, Unit>> call(int params) {
    return repository.deleteWorkout(params);
  }
}
