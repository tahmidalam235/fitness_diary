import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

class WatchWorkoutsForSession
    extends StreamUseCase<List<Workout>, int> {
  const WatchWorkoutsForSession({required this.repository});

  final WorkoutRepository repository;

  @override
  Stream<Either<Failure, List<Workout>>> call(int params) {
    return repository.watchWorkoutsForSession(params);
  }
}
