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
/// Subscribes to [WatchLogsInRange] for the 6-week window around the
/// visible month and aggregates streamed [WorkoutLog]s into a
/// date-keyed set of "completed" days.
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  CalendarBloc({required WatchLogsInRange watchLogsInRange})
      : _watchLogsInRange = watchLogsInRange,
        super(CalendarInitial()) {
    on<MonthChangedEvent>(_onMonthChanged);
    on<JumpToTodayEvent>(_onJumpToToday);
    on<LogsReceivedEvent>(_onLogsReceived);
    on<CalendarErrorEvent>(_onCalendarError);

    // Kick off the initial subscription to today's month.
    final now = DateTime.now();
    add(MonthChangedEvent(DateTime(now.year, now.month, 1)));
  }

  final WatchLogsInRange _watchLogsInRange;
  StreamSubscription<Either<Failure, List<WorkoutLog>>>? _sub;
  DateTime? _activeMonth;

  /// Returns the half-open `[start, end)` window covering a 6-row grid
  /// for [month]. Always Sunday-start week.
  ({DateTime start, DateTime end}) _windowFor(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    // weekday: Mon=1..Sun=7. Convert to Sunday-first: 0..6.
    final sundayOffset = first.weekday % 7;
    final start = first.subtract(Duration(days: sundayOffset));
    final end = start.add(const Duration(days: 42));
    return (start: start, end: end);
  }

  Future<void> _onMonthChanged(
    MonthChangedEvent event,
    Emitter<CalendarState> emit,
  ) async {
    // Normalise to a first-of-month DateTime so `==` comparisons work
    // regardless of whether the caller passed a DateTime with day/time
    // components.
    final month = DateTime(event.month.year, event.month.month, 1);
    if (_activeMonth == month) {
      // Already on this month — still ensure the UI shows the loaded
      // state in case the stream silently went silent.
      return;
    }
    _activeMonth = month;
    await _sub?.cancel();
    _sub = null;

    emit(CalendarLoading(visibleMonth: month));

    final window = _windowFor(month);
    _sub = _watchLogsInRange(
      DateRange(start: window.start, end: window.end),
    ).listen(
      (result) {
        result.fold(
          (failure) => add(CalendarErrorEvent(failure)),
          (logs) {
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
          },
        );
      },
    );
  }

  void _onJumpToToday(
    JumpToTodayEvent event,
    Emitter<CalendarState> emit,
  ) {
    final now = DateTime.now();
    add(MonthChangedEvent(DateTime(now.year, now.month, 1)));
  }

  void _onLogsReceived(
    LogsReceivedEvent event,
    Emitter<CalendarState> emit,
  ) {
    final month = _activeMonth;
    if (month == null) return;
    emit(CalendarLoaded(
      visibleMonth: month,
      daysWithLogs: event.daysWithLogs,
      workoutsByDay: event.workoutsByDay,
    ));
  }

  void _onCalendarError(
    CalendarErrorEvent event,
    Emitter<CalendarState> emit,
  ) {
    emit(CalendarError(event.failure));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}