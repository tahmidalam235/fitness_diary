import '../../../../core/error/failure.dart';
import '../../../../core/usecase/no_params.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

class WatchWorkoutsForSession extends StreamUseCase<List<Workout>, int> {
  const WatchWorkoutsForSession({required this.repository});

  final WorkoutRepository repository;

  @override
  Stream<Either<Failure, List<Workout>>> call(int params) {
    return repository.watchWorkoutsForSession(params);
  }
}

class WatchAllWorkouts extends StreamUseCase<List<Workout>, NoParams> {
  const WatchAllWorkouts({required this.repository});

  final WorkoutRepository repository;

  @override
  Stream<Either<Failure, List<Workout>>> call(NoParams params) {
    return repository.watchAllWorkouts();
  }
}
