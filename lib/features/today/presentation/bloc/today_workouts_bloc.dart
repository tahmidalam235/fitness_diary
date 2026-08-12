import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/domain/usecases/watch_workouts.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import '../../../workout_log/domain/usecases/find_today_log.dart';
import '../../../workout_log/domain/usecases/watch_today_entries_by_workout.dart';

// -----------------------------------------------------------------------------
// Events
// -----------------------------------------------------------------------------

sealed class TodayWorkoutsEvent extends Equatable {
  const TodayWorkoutsEvent();
  @override
  List<Object?> get props => const [];
}

/// Open the today stream for a given session id.
class WatchTodayWorkoutsEvent extends TodayWorkoutsEvent {
  const WatchTodayWorkoutsEvent(this.sessionId);
  final int sessionId;
  @override
  List<Object?> get props => [sessionId];
}

/// Internal — a fresh snapshot of today's workouts arrived.
class _TodayReceivedEvent extends TodayWorkoutsEvent {
  const _TodayReceivedEvent(this.entriesByWorkout);
  final Map<int, WorkoutLogEntry> entriesByWorkout;
  @override
  List<Object?> get props => [entriesByWorkout];
}

/// Internal — the list of master workouts (used to render exercise
/// names alongside the entries).
class _WorkoutsReceivedEvent extends TodayWorkoutsEvent {
  const _WorkoutsReceivedEvent(this.workoutsById);
  final Map<int, Workout> workoutsById;
  @override
  List<Object?> get props => [workoutsById];
}

/// Internal — the today's `WorkoutLog` row (or `null` if the log
/// doesn't exist yet — e.g. when this bloc is opened on the session
/// details page before the user picks a workout).
class _LogLoadedEvent extends TodayWorkoutsEvent {
  const _LogLoadedEvent(this.log);
  final WorkoutLog? log;
  @override
  List<Object?> get props => [log];
}

/// Internal — error carrier.
class _TodayErrorEvent extends TodayWorkoutsEvent {
  const _TodayErrorEvent(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

sealed class TodayWorkoutsState extends Equatable {
  const TodayWorkoutsState();
  @override
  List<Object?> get props => const [];
}

class TodayWorkoutsInitial extends TodayWorkoutsState {
  const TodayWorkoutsInitial();
}

class TodayWorkoutsLoading extends TodayWorkoutsState {
  const TodayWorkoutsLoading();
}

class TodayWorkoutsLoaded extends TodayWorkoutsState {
  const TodayWorkoutsLoaded({
    required this.sessionId,
    required this.workoutLog,
    required this.entries,
    required this.workoutsById,
  });

  final int sessionId;

  /// The today's [WorkoutLog] row for this session, or `null` if no
  /// log row has been created yet. Read-only consumers (the today
  /// page picker) use [FindTodayLog] which never creates a row, so
  /// `workoutLog` stays `null` until [AddWorkoutsToToday] creates
  /// one when the user actually picks a workout.
  final WorkoutLog? workoutLog;
  final List<WorkoutLogEntry> entries;
  final Map<int, Workout> workoutsById;

  TodayWorkoutsLoaded copyWith({
    int? sessionId,
    WorkoutLog? workoutLog,
    List<WorkoutLogEntry>? entries,
    Map<int, Workout>? workoutsById,
  }) {
    return TodayWorkoutsLoaded(
      sessionId: sessionId ?? this.sessionId,
      workoutLog: workoutLog ?? this.workoutLog,
      entries: entries ?? this.entries,
      workoutsById: workoutsById ?? this.workoutsById,
    );
  }

  @override
  List<Object?> get props => [sessionId, workoutLog, entries, workoutsById];
}

class TodayWorkoutsEmpty extends TodayWorkoutsState {
  const TodayWorkoutsEmpty();
}

class TodayWorkoutsError extends TodayWorkoutsState {
  const TodayWorkoutsError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

// -----------------------------------------------------------------------------
// Bloc
// -----------------------------------------------------------------------------

/// Streams today's [WorkoutLogEntry] rows for the picked session and
/// resolves exercise names via [WatchWorkoutsForSession]. The session's
/// master workouts are loaded once and the entries are joined against
/// them in [_onReceived].
///
/// Uses [FindTodayLog] (read-only) instead of [GetOrCreateTodayLog] —
/// opening this bloc must NOT create an empty log row, otherwise the
/// today page would render a session that the user picked and then
/// backed out of without selecting any workouts.
class TodayWorkoutsBloc extends Bloc<TodayWorkoutsEvent, TodayWorkoutsState> {
  TodayWorkoutsBloc({
    required WatchTodayEntriesByWorkout watchTodayEntriesByWorkout,
    required FindTodayLog findTodayLog,
    required WatchWorkoutsForSession watchWorkoutsForSession,
  }) : _watchTodayEntriesByWorkout = watchTodayEntriesByWorkout,
       _findTodayLog = findTodayLog,
       _watchWorkoutsForSession = watchWorkoutsForSession,
       super(const TodayWorkoutsInitial()) {
    on<WatchTodayWorkoutsEvent>(_onWatch);
    on<_TodayReceivedEvent>(_onReceived);
    on<_WorkoutsReceivedEvent>(_onWorkoutsReceived);
    on<_LogLoadedEvent>(_onLogLoaded);
    on<_TodayErrorEvent>(_onError);
  }

  final WatchTodayEntriesByWorkout _watchTodayEntriesByWorkout;
  final FindTodayLog _findTodayLog;
  final WatchWorkoutsForSession _watchWorkoutsForSession;

  StreamSubscription<Either<Failure, Map<int, WorkoutLogEntry>>>? _entriesSub;
  StreamSubscription<Either<Failure, List<Workout>>>? _workoutsSub;
  int? _sessionId;

  /// Master workouts keyed by [Workout.workoutId]. Stored on the bloc
  /// so that late-arriving entries can be joined against the workout
  /// name even if the state hasn't transitioned to
  /// [TodayWorkoutsLoaded] yet.
  Map<int, Workout> _latestWorkouts = const {};

  /// Latest snapshot of today's entries keyed by [WorkoutLogEntry.workoutId].
  /// Stored on the bloc so that the initial [TodayWorkoutsLoaded] emit
  /// (driven by the log fetch) can include entries even if the entries
  /// stream has already fired before the log fetch resolved.
  Map<int, WorkoutLogEntry> _latestEntries = const {};

  Future<void> _onWatch(
    WatchTodayWorkoutsEvent event,
    Emitter<TodayWorkoutsState> emit,
  ) async {
    _sessionId = event.sessionId;
    _latestWorkouts = const {};
    _latestEntries = const {};

    // Only emit loapuding if we don't have a valid state yet. This prevents
    // a "flicker" when the Bloc is recreated during a cloud restore.
    if (state is! TodayWorkoutsLoaded) {
      emit(const TodayWorkoutsLoading());
    }

    await _entriesSub?.cancel();
    await _workoutsSub?.cancel();
    _entriesSub = null;
    _workoutsSub = null;

    // Subscribe to the entries + workouts streams *before* awaiting the
    // log fetch. The streams run in parallel with the log lookup, so by
    // the time the UI subscribes to the bloc state the first snapshot
    // has usually already arrived and `_onReceived` /
    // `_onWorkoutsReceived` have populated the relevant fields stored
    // in `_latestEntries` / `_latestWorkouts`. When `_onLogLoaded` fires
    // later it emits the initial `TodayWorkoutsLoaded` with those
    // cached entries already populated, so the session-details picker
    // renders already-picked workouts with their checkboxes ticked on
    // the very first frame — no empty-checkbox flash.
    _entriesSub = _watchTodayEntriesByWorkout(event.sessionId).listen((result) {
      if (isClosed) return;
      result.fold(
        (failure) => add(_TodayErrorEvent(failure)),
        (entries) => add(_TodayReceivedEvent(entries)),
      );
    });
    _workoutsSub = _watchWorkoutsForSession(event.sessionId).listen((result) {
      if (isClosed) return;
      result.fold(
        (failure) => add(_TodayErrorEvent(failure)),
        (workouts) => add(
          _WorkoutsReceivedEvent({for (final w in workouts) w.workoutId: w}),
        ),
      );
    });

    // Run the entries fetch and the log fetch in parallel. The session-
    // details picker renders as soon as WorkoutListBloc emits its
    // Loaded state (typically within a frame of _onWatch returning).
    // Both the entries stream and the log fetch here hit Firestore;
    // running them concurrently means the total wall-clock time is
    // max(T_entries, T_log) instead of T_entries + T_log, which is what
    // lets `_onLogLoaded` emit a populated `TodayWorkoutsLoaded` on
    // its very first call. The entries `.first` snapshot is stored in
    // `_latestEntries` so even if it arrives second (vs the log), the
    // emit includes the tracked workouts.
    Future<void> firstEntriesTask() async {
      try {
        final firstEntries = await _watchTodayEntriesByWorkout(
          event.sessionId,
        ).first;
        _latestEntries = firstEntries.getOrElse(
          (_) => const <int, WorkoutLogEntry>{},
        );
      } catch (_) {
        // The live subscription above will retry; ignore the error
        // here so the bloc still reaches a usable Loaded state.
      }
    }

    Future<void> logTask() async {
      try {
        final result = await _findTodayLog(event.sessionId);
        result.fold(
          (failure) => add(_TodayErrorEvent(failure)),
          (log) => add(_LogLoadedEvent(log)),
        );
      } catch (_) {
        // Same as above — best-effort, ignore.
      }
    }

    // Run the entries fetch and the log fetch in parallel so the
    // total wall-clock time is max(T_entries, T_log). This makes it
    // likely that by the time `_onLogLoaded` fires, `_latestEntries`
    // is already populated and the initial emit can include the
    // tracked workouts — so the session-details picker renders with
    // already-picked checkboxes ticked on the very first frame,
    // instead of flashing unchecked for a moment.
    await Future.wait<void>([firstEntriesTask(), logTask()]);
  }

  Future<void> _onLogLoaded(
    _LogLoadedEvent event,
    Emitter<TodayWorkoutsState> emit,
  ) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    // Emit Loaded using whatever entries/workouts the streams have
    // already pushed into the bloc. Both stream subscriptions were
    // wired up in parallel with the log lookup in [_onWatch], so by
    // the time we get here the first snapshot has usually already
    // arrived and is sitting in [_latestEntries] / [_latestWorkouts].
    // Including them in this initial emit means the session-details
    // picker can render already-picked workouts with their checkboxes
    // ticked on the very first frame — no empty-checkbox flash.
    //
    // `workoutLog` may be `null` here when no log row exists yet
    // (e.g. the session-details page entered select mode without
    // any prior pick). That's expected — [AddWorkoutsToToday] is
    // what creates the log lazily on first pick, and the today
    // page's `_todayLogs` stream will surface the new log row when
    // it appears. No consumer of this bloc reads `workoutLog`, so
    // the null is benign.
    emit(
      TodayWorkoutsLoaded(
        sessionId: sessionId,
        workoutLog: event.log,
        entries: _latestEntries.values.toList(growable: false),
        workoutsById: _latestWorkouts,
      ),
    );

    // If we haven't subscribed to the entries stream yet (e.g. the log
    // lookup arrived before _onWatch finished wiring the subscriptions
    // up — shouldn't happen in practice but kept for safety), do it
    // now.
    _entriesSub ??= _watchTodayEntriesByWorkout(sessionId).listen((result) {
      if (isClosed) return;
      result.fold(
        (failure) => add(_TodayErrorEvent(failure)),
        (entries) => add(_TodayReceivedEvent(entries)),
      );
    });
    _workoutsSub ??= _watchWorkoutsForSession(sessionId).listen((result) {
      if (isClosed) return;
      result.fold(
        (failure) => add(_TodayErrorEvent(failure)),
        (workouts) => add(
          _WorkoutsReceivedEvent({for (final w in workouts) w.workoutId: w}),
        ),
      );
    });
  }

  void _onReceived(
    _TodayReceivedEvent event,
    Emitter<TodayWorkoutsState> emit,
  ) {
    _latestEntries = event.entriesByWorkout;
    final current = state;
    if (current is TodayWorkoutsLoaded) {
      emit(
        current.copyWith(
          entries: event.entriesByWorkout.values.toList(growable: false),
        ),
      );
    }
  }

  void _onWorkoutsReceived(
    _WorkoutsReceivedEvent event,
    Emitter<TodayWorkoutsState> emit,
  ) {
    _latestWorkouts = event.workoutsById;
    final current = state;
    if (current is TodayWorkoutsLoaded) {
      emit(current.copyWith(workoutsById: event.workoutsById));
    }
  }

  void _onError(_TodayErrorEvent event, Emitter<TodayWorkoutsState> emit) {
    emit(TodayWorkoutsError(event.failure));
  }

  @override
  Future<void> close() async {
    await _entriesSub?.cancel();
    await _workoutsSub?.cancel();
    return super.close();
  }
}
