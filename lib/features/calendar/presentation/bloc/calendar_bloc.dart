import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../history/domain/usecases/watch_logs_in_range.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../../workout_log/data/models/workout_log_entry_model.dart';
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
  CalendarBloc({
    required WatchLogsInRange watchLogsInRange,
    required WorkoutLogDao workoutLogDao,
  }) : _watchLogsInRange = watchLogsInRange,
       _workoutLogDao = workoutLogDao,
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
        _latestLogs = logs;
        _recomputeAndEmit();
      });
    });

    // Stream every workout entry so the per-day counts reflect the
    // number of *individual workouts/exercises* completed that day
    // (one entry per `(workoutLog, workout)` pair), not the number of
    // session-level logs. Without this, a session containing N
    // exercises only contributed 1 to the count regardless of how
    // many workouts the user actually did.
    _entriesSub = _workoutLogDao.watchAllEntries().listen((entries) {
      if (isClosed) return;
      _latestEntries = entries;
      _recomputeAndEmit();
    });
  }

  final WatchLogsInRange _watchLogsInRange;
  final WorkoutLogDao _workoutLogDao;
  StreamSubscription<Either<Failure, List<WorkoutLog>>>? _sub;
  StreamSubscription<List<WorkoutLogEntryModel>>? _entriesSub;

  List<WorkoutLog> _latestLogs = const [];
  List<WorkoutLogEntryModel> _latestEntries = const [];

  /// Rebuilds the [CalendarLoaded] state from the latest snapshot of
  /// logs + entries. Idempotent and safe to call from either stream
  /// listener; the bloc deduplicates emissions via [_emitIfChanged].
  void _recomputeAndEmit() {
    final logByFid = <String, WorkoutLog>{};
    for (final l in _latestLogs) {
      final fid = l.firestoreId;
      if (fid != null && fid.isNotEmpty) logByFid[fid] = l;
    }

    final days = <DateTime>{};
    final counts = <DateTime, int>{};
    for (final l in _latestLogs) {
      final d = DateTime(
        l.performedAt.year,
        l.performedAt.month,
        l.performedAt.day,
      );
      days.add(d);
    }
    for (final e in _latestEntries) {
      final logFid = e.workoutLogFirestoreId;
      if (logFid == null || logFid.isEmpty) continue;
      final parent = logByFid[logFid];
      if (parent == null) continue;
      final d = DateTime(
        parent.performedAt.year,
        parent.performedAt.month,
        parent.performedAt.day,
      );
      counts[d] = (counts[d] ?? 0) + 1;
    }

    final next = CalendarLoaded(
      daysWithLogs: days,
      workoutsByDay: counts,
    );
    final prev = state;
    if (prev is CalendarLoaded &&
        _mapEquals(prev.workoutsByDay, next.workoutsByDay) &&
        _setEquals(prev.daysWithLogs, next.daysWithLogs)) {
      return;
    }
    add(LogsReceivedEvent(next.daysWithLogs, next.workoutsByDay));
  }

  bool _mapEquals(Map<DateTime, int> a, Map<DateTime, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  bool _setEquals(Set<DateTime> a, Set<DateTime> b) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

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
    await _entriesSub?.cancel();
    return super.close();
  }
}
