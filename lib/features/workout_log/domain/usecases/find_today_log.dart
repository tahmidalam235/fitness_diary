import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/workout_log.dart';
import '../repositories/workout_log_repository.dart';

/// Read-only lookup of today's [WorkoutLog] for [params] (a session
/// id). Unlike [GetOrCreateTodayLog], this never creates a log row —
/// if none exists, it returns `null`. Used by read-only consumers
/// (e.g. the Today page's `TodayWorkoutsBloc`) so that opening a
/// session details page doesn't leave behind an empty log row when the
/// user backs out without picking a workout.
class FindTodayLog extends UseCase<WorkoutLog?, int> {
  const FindTodayLog({required this.repository});

  final WorkoutLogRepository repository;

  @override
  Future<Either<Failure, WorkoutLog?>> call(int params) {
    return repository.findTodayLog(params);
  }
}