import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../history/domain/entities/daily_log_group.dart';
import '../../../history/domain/usecases/get_workouts_by_ids.dart';
import '../../../history/domain/usecases/watch_entries_by_log_for_day.dart';
import '../../../history/domain/usecases/watch_logs_for_day.dart';
import '../../../session/domain/usecases/get_sessions_by_ids.dart';
import '../../../session/domain/entities/session.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import 'daily_details_event.dart';
import 'daily_details_state.dart';

/// Bloc that loads the day's logs, entries, and lookup maps for the
/// Daily Details page. Subscribes to streams reactively so any change
/// to the underlying logs (e.g. late-arriving writes) updates the UI.
class DailyDetailsBloc
    extends Bloc<DailyDetailsEvent, DailyDetailsState> {
  DailyDetailsBloc({
    required WatchLogsForDay watchLogsForDay,
    required WatchEntriesByLogForDay watchEntriesByLogForDay,
    required GetWorkoutsByIds getWorkoutsByIds,
    required GetSessionsByIds getSessionsByIds,
  })  : _watchLogsForDay = watchLogsForDay,
        _watchEntriesByLogForDay = watchEntriesByLogForDay,
        _getWorkoutsByIds = getWorkoutsByIds,
        _getSessionsByIds = getSessionsByIds,
        super(const DailyDetailsInitial()) {
    on<DaySelectedEvent>(_onDaySelected);
    on<LogsReceivedEvent>(_onLogsReceived);
    on<EntriesReceivedEvent>(_onEntriesReceived);
    on<WorkoutsReceivedEvent>(_onWorkoutsReceived);
    on<SessionsReceivedEvent>(_onSessionsReceived);
    on<DetailsErrorEvent>(_onError);
  }

  final WatchLogsForDay _watchLogsForDay;
  final WatchEntriesByLogForDay _watchEntriesByLogForDay;
  final GetWorkoutsByIds _getWorkoutsByIds;
  final GetSessionsByIds _getSessionsByIds;

  StreamSubscription<Either<Failure, List<WorkoutLog>>>? _logsSub;
  StreamSubscription<Either<Failure, Map<int, List<WorkoutLogEntry>>>>?
      _entriesSub;
  DateTime? _activeDate;

  /// Latest snapshot of all four data sources keyed by date.
  List<WorkoutLog> _logs = const [];
  Map<int, List<WorkoutLogEntry>> _entriesByLog = const {};
  Map<int, Workout> _workoutsById = const {};
  Map<int, Session> _sessionsById = const {};
  bool _gotLogs = false;
  bool _gotEntries = false;

  Future<void> _onDaySelected(
    DaySelectedEvent event,
    Emitter<DailyDetailsState> emit,
  ) async {
    final day = DateTime(event.day.year, event.day.month, event.day.day);
    if (_activeDate == day) return;
    _activeDate = day;
    _logs = const [];
    _entriesByLog = const {};
    _workoutsById = const {};
    _sessionsById = const {};
    _gotLogs = false;
    _gotEntries = false;
    _resolved = false;

    await _logsSub?.cancel();
    await _entriesSub?.cancel();
    _logsSub = null;
    _entriesSub = null;

    emit(DailyDetailsLoading(date: day));

    _logsSub = _watchLogsForDay(day).listen(
      (result) {
        result.fold(
          (failure) => add(DetailsErrorEvent(failure)),
          (logs) => add(LogsReceivedEvent(logs)),
        );
      },
    );

    _entriesSub = _watchEntriesByLogForDay(day).listen(
      (result) {
        result.fold(
          (failure) => add(DetailsErrorEvent(failure)),
          (entries) => add(EntriesReceivedEvent(entries)),
        );
      },
    );
  }

  void _onLogsReceived(
    LogsReceivedEvent event,
    Emitter<DailyDetailsState> emit,
  ) {
    _logs = event.logs;
    _gotLogs = true;
    _resolveLookups();
    _emitCurrent(emit);
  }

  void _onEntriesReceived(
    EntriesReceivedEvent event,
    Emitter<DailyDetailsState> emit,
  ) {
    _entriesByLog = event.entriesByLog;
    _gotEntries = true;
    _resolveLookups();
    _emitCurrent(emit);
  }

  void _onWorkoutsReceived(
    WorkoutsReceivedEvent event,
    Emitter<DailyDetailsState> emit,
  ) {
    _workoutsById = event.workoutsById;
    _emitCurrent(emit);
  }

  void _onSessionsReceived(
    SessionsReceivedEvent event,
    Emitter<DailyDetailsState> emit,
  ) {
    _sessionsById = event.sessionsById;
    _emitCurrent(emit);
  }

  void _onError(DetailsErrorEvent event, Emitter<DailyDetailsState> emit) {
    emit(DailyDetailsError(event.failure));
  }

  /// Triggers lazy lookup of workout/session names the first time we see
  /// the entries for the day. Runs at most once per DaySelectedEvent.
  bool _resolved = false;

  Future<void> _resolveLookups() async {
    if (_resolved) return;
    if (_logs.isEmpty) {
      // No logs yet — wait for both logs and entries to be empty.
      return;
    }
    _resolved = true;

    final workoutIds = <int>{};
    for (final entries in _entriesByLog.values) {
      for (final e in entries) {
        workoutIds.add(e.workoutId);
      }
    }
    final sessionIds = <int>{for (final l in _logs) l.sessionId};

    if (workoutIds.isNotEmpty) {
      final r = await _getWorkoutsByIds(workoutIds.toList());
      r.fold(
        (_) {},
        (map) => add(WorkoutsReceivedEvent(map)),
      );
    }
    if (sessionIds.isNotEmpty) {
      final r = await _getSessionsByIds(sessionIds.toList());
      r.fold(
        (_) {},
        (map) => add(SessionsReceivedEvent(map)),
      );
    }
  }

  void _emitCurrent(Emitter<DailyDetailsState> emit) {
    final date = _activeDate;
    if (date == null) return;

    // Wait until both streams have emitted at least once before deciding
    // Empty vs Loaded so a single fast-emit empty list doesn't flash the
    // empty state before the other stream has a chance to populate data.
    if (!_gotLogs || !_gotEntries) return;

    if (_logs.isEmpty && _entriesByLog.isEmpty) {
      emit(DailyDetailsEmpty(date: date));
      return;
    }

    final groups = <DailyLogGroup>[];
    for (final log in _logs) {
      groups.add(DailyLogGroup(
        log: log,
        entries: _entriesByLog[log.id] ?? const [],
      ));
    }
    emit(DailyDetailsLoaded(
      date: date,
      groups: groups,
      workoutsById: _workoutsById,
      sessionsById: _sessionsById,
    ));
  }

  @override
  Future<void> close() async {
    await _logsSub?.cancel();
    await _entriesSub?.cancel();
    return super.close();
  }
}