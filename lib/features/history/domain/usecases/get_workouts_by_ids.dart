import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../domain/repositories/history_repository.dart';

/// One-shot lookup of master [Workout]s by id. Used by the Daily Details
/// page to render exercise names after the entries stream emits.
class GetWorkoutsByIds extends UseCase<Map<int, Workout>, List<int>> {
  const GetWorkoutsByIds({required this.repository});

  final HistoryRepository repository;

  @override
  Future<Either<Failure, Map<int, Workout>>> call(List<int> params) {
    return repository.getWorkoutsByIds(params);
  }
}
