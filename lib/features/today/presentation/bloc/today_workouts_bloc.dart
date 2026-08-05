import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/domain/usecases/watch_workouts.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import '../../../workout_log/domain/usecases/get_or_create_today_log.dart';
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

/// Internal — the today's `WorkoutLog` row.
class _LogLoadedEvent extends TodayWorkoutsEvent {
  const _LogLoadedEvent(this.log);
  final WorkoutLog log;
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
  final WorkoutLog workoutLog;
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
class TodayWorkoutsBloc extends Bloc<TodayWorkoutsEvent, TodayWorkoutsState> {
  TodayWorkoutsBloc({
    required WatchTodayEntriesByWorkout watchTodayEntriesByWorkout,
    required GetOrCreateTodayLog getOrCreateTodayLog,
    required WatchWorkoutsForSession watchWorkoutsForSession,
  }) : _watchTodayEntriesByWorkout = watchTodayEntriesByWorkout,
       _getOrCreateTodayLog = getOrCreateTodayLog,
       _watchWorkoutsForSession = watchWorkoutsForSession,
       super(const TodayWorkoutsInitial()) {
    on<WatchTodayWorkoutsEvent>(_onWatch);
    on<_TodayReceivedEvent>(_onReceived);
    on<_WorkoutsReceivedEvent>(_onWorkoutsReceived);
    on<_LogLoadedEvent>(_onLogLoaded);
    on<_TodayErrorEvent>(_onError);
  }

  final WatchTodayEntriesByWorkout _watchTodayEntriesByWorkout;
  final GetOrCreateTodayLog _getOrCreateTodayLog;
  final WatchWorkoutsForSession _watchWorkoutsForSession;

  StreamSubscription<Either<Failure, Map<int, WorkoutLogEntry>>>? _entriesSub;
  StreamSubscription<Either<Failure, List<Workout>>>? _workoutsSub;
  int? _sessionId;

  /// names alongside the entries).
  Map<int, Workout> _latestWorkouts = const {};

  Future<void> _onWatch(
    WatchTodayWorkoutsEvent event,
    Emitter<TodayWorkoutsState> emit,
  ) async {
    _sessionId = event.sessionId;
    _latestWorkouts = const {};
    emit(const TodayWorkoutsLoading());

    await _entriesSub?.cancel();
    await _workoutsSub?.cancel();
    _entriesSub = null;
    _workoutsSub = null;

    final logResult = await _getOrCreateTodayLog(event.sessionId);
    logResult.fold(
      (failure) => add(_TodayErrorEvent(failure)),
      (log) => add(_LogLoadedEvent(log)),
    );
  }

  Future<void> _onLogLoaded(
    _LogLoadedEvent event,
    Emitter<TodayWorkoutsState> emit,
  ) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    // First, try to get existing entries for today's log.
    final initialEntriesResult = await _watchTodayEntriesByWorkout(
      sessionId,
    ).first;
    final initialEntries = initialEntriesResult
        .getOrElse((_) => const {})
        .values
        .toList();

    emit(
      TodayWorkoutsLoaded(
        sessionId: sessionId,
        workoutLog: event.log,
        entries: initialEntries,
        workoutsById: _latestWorkouts,
      ),
    );

    _entriesSub = _watchTodayEntriesByWorkout(sessionId).listen((result) {
      result.fold(
        (failure) => add(_TodayErrorEvent(failure)),
        (entries) => add(_TodayReceivedEvent(entries)),
      );
    });

    _workoutsSub = _watchWorkoutsForSession(sessionId).listen((result) {
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
    final entries = event.entriesByWorkout.values.toList(growable: false);
    final current = state;
    if (current is TodayWorkoutsLoaded) {
      emit(current.copyWith(entries: entries));
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
