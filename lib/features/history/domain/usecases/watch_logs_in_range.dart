import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../domain/repositories/history_repository.dart';

class DateRange extends Equatable {
  const DateRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}

/// Streams every [WorkoutLog] whose `performedAt` falls in the half-open
/// range `[start, end)`. Used by the calendar grid.
class WatchLogsInRange extends StreamUseCase<List<WorkoutLog>, DateRange> {
  const WatchLogsInRange({required this.repository});

  final HistoryRepository repository;

  @override
  Stream<Either<Failure, List<WorkoutLog>>> call(DateRange params) {
    return repository.watchLogsInRange(
      start: params.start,
      end: params.end,
    );
  }
}