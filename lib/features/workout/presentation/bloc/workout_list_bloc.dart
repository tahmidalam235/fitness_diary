import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/body_part.dart';
import '../../domain/entities/workout.dart';
import '../../domain/usecases/add_workout.dart';
import '../../domain/usecases/delete_workout.dart';
import '../../domain/usecases/reorder_workouts.dart';
import '../../domain/usecases/update_workout.dart';
import '../../domain/usecases/watch_workouts.dart';

// -----------------------------------------------------------------------------
// Events
// -----------------------------------------------------------------------------

sealed class WorkoutListEvent extends Equatable {
  const WorkoutListEvent();

  @override
  List<Object?> get props => const [];
}

class WatchWorkoutsEvent extends WorkoutListEvent {
  const WatchWorkoutsEvent(this.sessionId);
  final int sessionId;
  @override
  List<Object?> get props => [sessionId];
}

class WorkoutsReceived extends WorkoutListEvent {
  const WorkoutsReceived(this.workouts);
  final List<Workout> workouts;
  @override
  List<Object?> get props => [workouts];
}

class AddWorkoutEvent extends WorkoutListEvent {
  const AddWorkoutEvent({
    required this.sessionId,
    required this.exerciseName,
    required this.defaultSets,
    required this.defaultReps,
    this.defaultDurationSeconds,
    this.defaultWeight,
    this.notes = '',
    this.targetedBodyPart,
  });

  final int sessionId;
  final String exerciseName;
  final int defaultSets;
  final int defaultReps;
  final int? defaultDurationSeconds;
  final double? defaultWeight;
  final String notes;
  final BodyPart? targetedBodyPart;

  @override
  List<Object?> get props => [
    sessionId,
    exerciseName,
    defaultSets,
    defaultReps,
    defaultDurationSeconds,
    defaultWeight,
    notes,
    targetedBodyPart,
  ];
}

class UpdateWorkoutEvent extends WorkoutListEvent {
  const UpdateWorkoutEvent({
    required this.id,
    required this.exerciseName,
    required this.defaultSets,
    required this.defaultReps,
    this.defaultDurationSeconds,
    this.defaultWeight,
    this.notes = '',
    this.targetedBodyPart,
  });

  final int id;
  final String exerciseName;
  final int defaultSets;
  final int defaultReps;
  final int? defaultDurationSeconds;
  final double? defaultWeight;
  final String notes;
  final BodyPart? targetedBodyPart;

  @override
  List<Object?> get props => [
    id,
    exerciseName,
    defaultSets,
    defaultReps,
    defaultDurationSeconds,
    defaultWeight,
    notes,
    targetedBodyPart,
  ];
}

class DeleteWorkoutEvent extends WorkoutListEvent {
  const DeleteWorkoutEvent(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

class ReorderWorkoutsEvent extends WorkoutListEvent {
  const ReorderWorkoutsEvent(this.orderedIds);
  final List<int> orderedIds;
  @override
  List<Object?> get props => [orderedIds];
}

class MutationStarted extends WorkoutListEvent {
  const MutationStarted();
}

class MutationFinished extends WorkoutListEvent {
  const MutationFinished();
}

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

sealed class WorkoutListState extends Equatable {
  const WorkoutListState();

  @override
  List<Object?> get props => const [];
}

class WorkoutListInitial extends WorkoutListState {
  const WorkoutListInitial();
}

class WorkoutListLoading extends WorkoutListState {
  const WorkoutListLoading();
}

class WorkoutListLoaded extends WorkoutListState {
  const WorkoutListLoaded({
    required this.sessionId,
    required this.workouts,
    this.isMutating = false,
  });

  final int sessionId;
  final List<Workout> workouts;
  final bool isMutating;

  WorkoutListLoaded copyWith({
    int? sessionId,
    List<Workout>? workouts,
    bool? isMutating,
  }) {
    return WorkoutListLoaded(
      sessionId: sessionId ?? this.sessionId,
      workouts: workouts ?? this.workouts,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [sessionId, workouts, isMutating];
}

class WorkoutListError extends WorkoutListState {
  const WorkoutListError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

// -----------------------------------------------------------------------------
// Bloc
// -----------------------------------------------------------------------------

class WorkoutListBloc extends Bloc<WorkoutListEvent, WorkoutListState> {
  WorkoutListBloc({
    required WatchWorkoutsForSession watchWorkouts,
    required AddWorkoutToSession addWorkout,
    required UpdateWorkout updateWorkout,
    required DeleteWorkout deleteWorkout,
    required ReorderWorkouts reorderWorkouts,
  }) : _watchWorkouts = watchWorkouts,
       _addWorkout = addWorkout,
       _updateWorkout = updateWorkout,
       _deleteWorkout = deleteWorkout,
       _reorderWorkouts = reorderWorkouts,
       super(const WorkoutListInitial()) {
    on<WatchWorkoutsEvent>(_onWatch);
    on<WorkoutsReceived>(_onReceived);
    on<AddWorkoutEvent>(_onAdd);
    on<UpdateWorkoutEvent>(_onUpdate);
    on<DeleteWorkoutEvent>(_onDelete);
    on<ReorderWorkoutsEvent>(_onReorder);
    on<MutationStarted>(_onMutationStarted);
    on<MutationFinished>(_onMutationFinished);
  }

  final WatchWorkoutsForSession _watchWorkouts;
  final AddWorkoutToSession _addWorkout;
  final UpdateWorkout _updateWorkout;
  final DeleteWorkout _deleteWorkout;
  final ReorderWorkouts _reorderWorkouts;

  StreamSubscription<Either<Failure, List<Workout>>>? _subscription;
  int? _currentSessionId;

  Future<void> _onWatch(
    WatchWorkoutsEvent event,
    Emitter<WorkoutListState> emit,
  ) async {
    _currentSessionId = event.sessionId;
    emit(WorkoutListLoading());
    await _subscription?.cancel();
    _subscription = _watchWorkouts(event.sessionId).listen(
      (result) {
        if (isClosed) return;
        add(WorkoutsReceived(result.getOrElse((_) => const [])));
      },
      onError: (Object error) {
        if (isClosed) return;
        add(const WorkoutsReceived(<Workout>[]));
      },
    );
  }

  void _onReceived(WorkoutsReceived event, Emitter<WorkoutListState> emit) {
    final sessionId = _currentSessionId;
    if (sessionId == null) return;
    final current = state;
    if (current is WorkoutListLoaded) {
      emit(current.copyWith(sessionId: sessionId, workouts: event.workouts));
    } else {
      emit(WorkoutListLoaded(sessionId: sessionId, workouts: event.workouts));
    }
  }

  Future<void> _onAdd(
    AddWorkoutEvent event,
    Emitter<WorkoutListState> emit,
  ) async {
    // The event carries the canonical sessionId — it always wins over any
    // internal state. The internal _currentSessionId is only consulted as
    // a defensive fallback if the event somehow has a 0 (which should
    // never happen given the form page passes the route parameter).
    final sessionId = event.sessionId != 0
        ? event.sessionId
        : (_currentSessionId ?? 0);
    if (sessionId <= 0) {
      emit(
        const WorkoutListError(
          ValidationFailure(
            message: 'No session selected',
            errors: {'sessionId': 'No session selected'},
          ),
        ),
      );
      return;
    }

    add(const MutationStarted());
    final result = await _addWorkout(
      AddWorkoutParams(
        sessionId: sessionId,
        exerciseName: event.exerciseName,
        defaultSets: event.defaultSets,
        defaultReps: event.defaultReps,
        defaultDurationSeconds: event.defaultDurationSeconds,
        defaultWeight: event.defaultWeight,
        notes: event.notes,
        targetedBodyPart: event.targetedBodyPart,
      ),
    );
    result.fold((failure) {
      emit(WorkoutListError(failure));
      add(const MutationFinished());
    }, (_) => add(const MutationFinished()));
  }

  Future<void> _onUpdate(
    UpdateWorkoutEvent event,
    Emitter<WorkoutListState> emit,
  ) async {
    add(const MutationStarted());
    final result = await _updateWorkout(
      UpdateWorkoutParams(
        id: event.id,
        exerciseName: event.exerciseName,
        defaultSets: event.defaultSets,
        defaultReps: event.defaultReps,
        defaultDurationSeconds: event.defaultDurationSeconds,
        defaultWeight: event.defaultWeight,
        notes: event.notes,
        targetedBodyPart: event.targetedBodyPart,
      ),
    );
    result.fold((failure) {
      emit(WorkoutListError(failure));
      add(const MutationFinished());
    }, (_) => add(const MutationFinished()));
  }

  Future<void> _onDelete(
    DeleteWorkoutEvent event,
    Emitter<WorkoutListState> emit,
  ) async {
    add(const MutationStarted());
    final result = await _deleteWorkout(event.id);
    result.fold((failure) {
      emit(WorkoutListError(failure));
      add(const MutationFinished());
    }, (_) => add(const MutationFinished()));
  }

  Future<void> _onReorder(
    ReorderWorkoutsEvent event,
    Emitter<WorkoutListState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutListLoaded) return;
    final optimistic = _reorder(current.workouts, event.orderedIds);
    emit(current.copyWith(workouts: optimistic));

    final result = await _reorderWorkouts(
      ReorderWorkoutsParams(
        sessionId: current.sessionId,
        orderedIds: event.orderedIds,
      ),
    );
    result.fold(
      (failure) => emit(WorkoutListError(failure)),
      (_) {}, // optimistic update sticks; stream will reconcile
    );
  }

  void _onMutationStarted(
    MutationStarted event,
    Emitter<WorkoutListState> emit,
  ) {
    final current = state;
    if (current is WorkoutListLoaded) {
      emit(current.copyWith(isMutating: true));
    }
  }

  void _onMutationFinished(
    MutationFinished event,
    Emitter<WorkoutListState> emit,
  ) {
    final current = state;
    if (current is WorkoutListLoaded) {
      emit(current.copyWith(isMutating: false));
    }
  }

  /// Returns a new list reordered so its ids match [orderedIds].
  List<Workout> _reorder(List<Workout> source, List<int> orderedIds) {
    final byId = {for (final w in source) w.id: w};
    final reordered = <Workout>[];
    for (var i = 0; i < orderedIds.length; i++) {
      final w = byId[orderedIds[i]];
      if (w != null) {
        reordered.add(w.copyWith(position: i));
      }
    }
    return reordered;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
