import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../history/domain/usecases/watch_logs_in_range.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

/// Bloc that owns the calendar grid state.
///
/// Subscribes to [WatchLogsInRange] for the full window the calendar
/// view exposes (-10 years to +10 years from today) and aggregates
/// streamed [WorkoutLog]s into a date-keyed set of "completed" days.
/// The view slices the result by month; no per-month resubscription is
/// needed because the underlying query is a single reactive Drift
/// query and the resulting set is small enough to hold in memory.
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  CalendarBloc({required WatchLogsInRange watchLogsInRange})
    : _watchLogsInRange = watchLogsInRange,
      super(const CalendarLoading()) {
    on<LogsReceivedEvent>(_onLogsReceived);
    on<CalendarErrorEvent>(_onCalendarError);

    final now = DateTime.now();
    // Jan-1 boundaries half-open on the right so we include every day
    // of the trailing December without an off-by-one. 21 years × 12
    // months = 252, but [_kTotalMonths] renders 240 (20y) and the
    // extra year is buffer for queries that span Dec → Jan.
    final start = DateTime(now.year - 10, 1, 1);
    final end = DateTime(now.year + 11, 1, 1);

    _sub = _watchLogsInRange(DateRange(start: start, end: end)).listen((
      result,
    ) {
      if (isClosed) return;
      result.fold((failure) => add(CalendarErrorEvent(failure)), (logs) {
        final days = <DateTime>{};
        final counts = <DateTime, int>{};
        for (final l in logs) {
          final d = DateTime(
            l.performedAt.year,
            l.performedAt.month,
            l.performedAt.day,
          );
          days.add(d);
          counts[d] = (counts[d] ?? 0) + 1;
        }
        add(LogsReceivedEvent(days, counts));
      });
    });
  }

  final WatchLogsInRange _watchLogsInRange;
  StreamSubscription<Either<Failure, List<WorkoutLog>>>? _sub;

  void _onLogsReceived(LogsReceivedEvent event, Emitter<CalendarState> emit) {
    emit(
      CalendarLoaded(
        daysWithLogs: event.daysWithLogs,
        workoutsByDay: event.workoutsByDay,
      ),
    );
  }

  void _onCalendarError(CalendarErrorEvent event, Emitter<CalendarState> emit) {
    emit(CalendarError(event.failure));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
