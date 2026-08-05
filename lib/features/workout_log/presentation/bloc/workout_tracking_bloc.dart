import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../domain/entities/workout_log.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../../domain/usecases/add_workouts_to_today.dart';
import '../../domain/usecases/delete_entry.dart';
import '../../domain/usecases/get_last_entries_for_workouts.dart';
import '../../domain/usecases/get_or_create_today_log.dart';
import '../../domain/usecases/upsert_entry.dart';
import '../../domain/usecases/watch_today_entries_by_workout.dart';

// -----------------------------------------------------------------------------
// Events
// -----------------------------------------------------------------------------

sealed class WorkoutTrackingEvent extends Equatable {
  const WorkoutTrackingEvent();
  @override
  List<Object?> get props => const [];
}

/// Open the tracking screen for a single master workout within [sessionId].
class InitTrackingEvent extends WorkoutTrackingEvent {
  const InitTrackingEvent({required this.sessionId, required this.workout});
  final int sessionId;
  final Workout workout;
  @override
  List<Object?> get props => [sessionId, workout];
}

/// Internal event used to push the just-loaded log into the bloc.
class _LogLoadedEvent extends WorkoutTrackingEvent {
  const _LogLoadedEvent(this.log);
  final WorkoutLog log;
  @override
  List<Object?> get props => [log];
}

/// Internal event carrying a fresh snapshot of today's `Map<workoutId,
/// entry>` stream.
class _EntriesReceivedEvent extends WorkoutTrackingEvent {
  const _EntriesReceivedEvent(this.entriesByWorkout);
  final Map<int, WorkoutLogEntry> entriesByWorkout;
  @override
  List<Object?> get props => [entriesByWorkout];
}

/// Persists edits to the single today's entry for the active workout.
class UpsertTodayEntryEvent extends WorkoutTrackingEvent {
  const UpsertTodayEntryEvent({
    this.sets,
    this.reps,
    this.weight,
    this.durationSeconds,
    this.notes,
  });

  final int? sets;
  final int? reps;
  final double? weight;
  final int? durationSeconds;
  final String? notes;

  @override
  List<Object?> get props => [sets, reps, weight, durationSeconds, notes];
}

/// Deletes today's entry for the active workout.
class DeleteTodayEntryEvent extends WorkoutTrackingEvent {
  const DeleteTodayEntryEvent();
}

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

sealed class WorkoutTrackingState extends Equatable {
  const WorkoutTrackingState();
  @override
  List<Object?> get props => const [];
}

class WorkoutTrackingInitial extends WorkoutTrackingState {
  const WorkoutTrackingInitial();
}

class WorkoutTrackingLoading extends WorkoutTrackingState {
  const WorkoutTrackingLoading();
}

class WorkoutTrackingLoaded extends WorkoutTrackingState {
  const WorkoutTrackingLoaded({
    required this.workoutLog,
    required this.workout,
    required this.entriesByWorkout,
  });

  final WorkoutLog workoutLog;
  final Workout workout;

  /// Today's entries keyed by master workout id. The entry for the
  /// active workout is exposed via [entry]; the map is kept for the
  /// Today page reuse.
  final Map<int, WorkoutLogEntry> entriesByWorkout;

  /// The single entry for the active workout, or `null` if the user
  /// hasn't recorded anything yet today.
  WorkoutLogEntry? get entry => entriesByWorkout[workout.workoutId];

  WorkoutTrackingLoaded copyWith({
    WorkoutLog? workoutLog,
    Workout? workout,
    Map<int, WorkoutLogEntry>? entriesByWorkout,
  }) {
    return WorkoutTrackingLoaded(
      workoutLog: workoutLog ?? this.workoutLog,
      workout: workout ?? this.workout,
      entriesByWorkout: entriesByWorkout ?? this.entriesByWorkout,
    );
  }

  @override
  List<Object?> get props => [workoutLog, workout, entriesByWorkout];
}

class WorkoutTrackingError extends WorkoutTrackingState {
  const WorkoutTrackingError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

class WorkoutTrackingDeleted extends WorkoutTrackingState {
  const WorkoutTrackingDeleted();
}

// -----------------------------------------------------------------------------
// Bloc
// -----------------------------------------------------------------------------

/// Bloc orchestrating the single-card tracking flow.
///
/// On init we get/create today's `WorkoutLog`, subscribe to today's
/// `Map<workoutId, entry>` stream, and remember the active workout.
/// The first time we open a workout on a given day we may also seed a
/// blank entry (so the user can start typing) — but only if there is
/// already a log row for today. If the log doesn't exist yet, the user
/// is expected to add the workout to today's session from the Session
/// details page first.
class WorkoutTrackingBloc
    extends Bloc<WorkoutTrackingEvent, WorkoutTrackingState> {
  WorkoutTrackingBloc({
    required GetOrCreateTodayLog getOrCreateTodayLog,
    required WatchTodayEntriesByWorkout watchTodayEntriesByWorkout,
    required UpsertEntry upsertEntry,
    required DeleteEntry deleteEntry,
    required GetLastEntriesForWorkouts getLastEntriesForWorkouts,
    required AddWorkoutsToToday addWorkoutsToToday,
  }) : _getOrCreateTodayLog = getOrCreateTodayLog,
       _watchTodayEntriesByWorkout = watchTodayEntriesByWorkout,
       _upsertEntry = upsertEntry,
       _deleteEntry = deleteEntry,
       _getLastEntriesForWorkouts = getLastEntriesForWorkouts,
       _addWorkoutsToToday = addWorkoutsToToday,
       super(const WorkoutTrackingInitial()) {
    on<InitTrackingEvent>(_onInit);
    on<_LogLoadedEvent>(_onLogLoaded);
    on<_EntriesReceivedEvent>(_onEntriesReceived);
    on<UpsertTodayEntryEvent>(_onUpsert);
    on<DeleteTodayEntryEvent>(_onDelete);
  }

  final GetOrCreateTodayLog _getOrCreateTodayLog;
  final WatchTodayEntriesByWorkout _watchTodayEntriesByWorkout;
  final UpsertEntry _upsertEntry;
  final DeleteEntry _deleteEntry;
  final GetLastEntriesForWorkouts _getLastEntriesForWorkouts;
  final AddWorkoutsToToday _addWorkoutsToToday;

  StreamSubscription<Either<Failure, Map<int, WorkoutLogEntry>>>? _sub;
  int? _sessionId;
  Workout? _workout;
  WorkoutLog? _log;

  Future<void> _onInit(
    InitTrackingEvent event,
    Emitter<WorkoutTrackingState> emit,
  ) async {
    _sessionId = event.sessionId;
    _workout = event.workout;
    emit(const WorkoutTrackingLoading());

    final logResult = await _getOrCreateTodayLog(event.sessionId);
    logResult.fold(
      (failure) => emit(WorkoutTrackingError(failure)),
      (log) => add(_LogLoadedEvent(log)),
    );
  }

  Future<void> _onLogLoaded(
    _LogLoadedEvent event,
    Emitter<WorkoutTrackingState> emit,
  ) async {
    final sessionId = _sessionId;
    final workout = _workout;
    if (sessionId == null || workout == null) return;
    _log = event.log;

    await _sub?.cancel();
    _sub = null;

    _sub = _watchTodayEntriesByWorkout(sessionId).listen(
      (result) => add(
        _EntriesReceivedEvent(
          result.getOrElse((_) => const <int, WorkoutLogEntry>{}),
        ),
      ),
    );

    // If today's log doesn't yet have an entry for this workout, seed
    // one pre-filled from the most recent prior record (or the template
    // defaults if there is no prior record). The DB insert will trigger
    // the stream subscription above to emit a fresh snapshot, which
    // will then transition us out of Loading in `_onEntriesReceived`.
    final entriesResult = await _watchTodayEntriesByWorkout(sessionId).first;
    final entriesByWorkout = entriesResult.getOrElse(
      (_) => const <int, WorkoutLogEntry>{},
    );
    if (!entriesByWorkout.containsKey(workout.workoutId)) {
      final lastResult = await _getLastEntriesForWorkouts(<int>[
        workout.workoutId,
      ]);
      final prior = lastResult.fold(
        (failure) => const <int, WorkoutLogEntry>{},
        (map) => map,
      )[workout.workoutId];
      final seed = _seedEntry(log: event.log, workout: workout, prior: prior);
      final addResult = await _addWorkoutsToToday(
        AddWorkoutsToTodayParams(
          sessionId: sessionId,
          entries: <WorkoutLogEntry>[seed],
        ),
      );
      addResult.fold((failure) => emit(WorkoutTrackingError(failure)), (_) {});
      return;
    }

    emit(
      WorkoutTrackingLoaded(
        workoutLog: event.log,
        workout: workout,
        entriesByWorkout: entriesByWorkout,
      ),
    );
  }

  void _onEntriesReceived(
    _EntriesReceivedEvent event,
    Emitter<WorkoutTrackingState> emit,
  ) {
    final workout = _workout;
    final log = _log;
    if (workout == null || log == null) return;
    final current = state;
    if (current is WorkoutTrackingLoaded) {
      emit(current.copyWith(entriesByWorkout: event.entriesByWorkout));
      return;
    }
    if (current is WorkoutTrackingLoading) {
      emit(
        WorkoutTrackingLoaded(
          workoutLog: log,
          workout: workout,
          entriesByWorkout: event.entriesByWorkout,
        ),
      );
    }
  }

  Future<void> _onUpsert(
    UpsertTodayEntryEvent event,
    Emitter<WorkoutTrackingState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutTrackingLoaded) return;
    final existing = current.entry;
    final workout = _workout;
    if (workout == null) return;

    final base =
        existing ??
        WorkoutLogEntry(
          id: 0,
          workoutLogId: current.workoutLog.id,
          workoutId: workout.workoutId,
          setIndex: 1,
          position: 0,
          sets: workout.defaultSets,
          reps: workout.defaultReps,
          weight: workout.defaultWeight,
          durationSeconds: workout.defaultDurationSeconds,
        );
    final updated = base.copyWith(
      sets: event.sets ?? base.sets,
      reps: event.reps ?? base.reps,
      weight: event.weight ?? base.weight,
      durationSeconds: event.durationSeconds ?? base.durationSeconds,
      notes: event.notes ?? base.notes,
    );

    final result = await _upsertEntry(updated);
    result.fold(
      (failure) => emit(WorkoutTrackingError(failure)),
      (_) {}, // stream will reconcile
    );
  }

  Future<void> _onDelete(
    DeleteTodayEntryEvent event,
    Emitter<WorkoutTrackingState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutTrackingLoaded) return;
    final entry = current.entry;
    if (entry == null || entry.id == 0) return;
    final result = await _deleteEntry(entry.id);
    result.fold(
      (failure) => emit(WorkoutTrackingError(failure)),
      (_) => emit(const WorkoutTrackingDeleted()),
    );
  }

  /// Builds the seed row for the first time the workout is opened
  /// today: prefer the most recent prior entry, fall back to the
  /// template's `defaultSets/Reps/Duration/Weight`.
  WorkoutLogEntry _seedEntry({
    required WorkoutLog log,
    required Workout workout,
    WorkoutLogEntry? prior,
  }) {
    return WorkoutLogEntry(
      id: 0,
      workoutLogId: log.id,
      workoutId: workout.workoutId,
      setIndex: 1,
      position: 0,
      sets: prior?.sets ?? workout.defaultSets,
      reps: prior?.reps ?? workout.defaultReps,
      weight: prior?.weight ?? workout.defaultWeight,
      durationSeconds: prior?.durationSeconds ?? workout.defaultDurationSeconds,
      notes: '',
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
