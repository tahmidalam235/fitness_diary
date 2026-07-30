import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../repositories/workout_repository.dart';

class ReorderWorkoutsParams {
  const ReorderWorkoutsParams({
    required this.sessionId,
    required this.orderedIds,
  });

  final int sessionId;
  final List<int> orderedIds;
}

class ReorderWorkouts extends UseCase<Unit, ReorderWorkoutsParams> {
  const ReorderWorkouts({required this.repository});

  final WorkoutRepository repository;

  @override
  Future<Either<Failure, Unit>> call(ReorderWorkoutsParams params) {
    return repository.reorderWorkouts(
      sessionId: params.sessionId,
      orderedIds: params.orderedIds,
    );
  }
}
