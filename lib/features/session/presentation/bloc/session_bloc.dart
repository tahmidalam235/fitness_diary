import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/no_params.dart';
import '../../../../core/utils/either.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/domain/usecases/watch_workouts.dart';
import '../../domain/entities/session.dart';
import '../../domain/usecases/create_session.dart';
import '../../domain/usecases/delete_session.dart';
import '../../domain/usecases/get_session_by_id.dart';
import '../../domain/usecases/get_sessions.dart';
import '../../domain/usecases/update_session.dart';
import '../../domain/usecases/watch_sessions.dart';
import 'session_event.dart';
import 'session_state.dart';

/// Bloc orchestrating the Sessions feature.
///
/// Owns the live subscription to the sessions table. Mutations trigger
/// a re-emit from Drift; we just pass the updated state through.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({
    required GetSessions getSessions,
    required WatchSessions watchSessions,
    required GetSessionById getSessionById,
    required CreateSession createSession,
    required UpdateSession updateSession,
    required DeleteSession deleteSession,
    required WatchAllWorkouts watchAllWorkouts,
  }) : _getSessions = getSessions,
       _watchSessions = watchSessions,
       _getSessionById = getSessionById,
       _createSession = createSession,
       _updateSession = updateSession,
       _deleteSession = deleteSession,
       _watchAllWorkouts = watchAllWorkouts,
       super(const SessionInitial()) {
    on<WatchSessionsEvent>(_onWatch);
    on<SessionsReceived>(_onReceived);
    on<WorkoutCountsReceived>(_onWorkoutCountsReceived);
    on<LoadSessionsEvent>(_onLoad);
    on<GetSessionByIdEvent>(_onGetById);
    on<SessionReceived>(_onSessionReceived);
    on<CreateSessionEvent>(_onCreate);
    on<UpdateSessionEvent>(_onUpdate);
    on<DeleteSessionEvent>(_onDelete);
    on<MutationStarted>(_onMutationStarted);
    on<MutationFinished>(_onMutationFinished);
  }

  final GetSessions _getSessions;
  final WatchSessions _watchSessions;
  final GetSessionById _getSessionById;
  final CreateSession _createSession;
  final UpdateSession _updateSession;
  final DeleteSession _deleteSession;
  final WatchAllWorkouts _watchAllWorkouts;

  StreamSubscription<Either<Failure, List<Session>>>? _subscription;
  StreamSubscription<Either<Failure, List<Workout>>>? _workoutsSubscription;

  Map<int, int> _workoutCountsBySessionId = const {};

  Future<void> _onWatch(
    WatchSessionsEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());
    await _subscription?.cancel();
    _subscription = _watchSessions(const NoParams()).listen(
      (result) {
        if (isClosed) return;
        add(SessionsReceived(result.getOrElse((_) => const [])));
      },
      onError: (Object error) {
        if (isClosed) return;
        add(SessionsReceived(const <Session>[]));
      },
    );
    await _workoutsSubscription?.cancel();
    _workoutsSubscription = _watchAllWorkouts(const NoParams()).listen(
      (result) {
        if (isClosed) return;
        add(WorkoutCountsReceived(result.getOrElse((_) => const [])));
      },
      onError: (Object error) {
        if (isClosed) return;
        add(WorkoutCountsReceived(const <Workout>[]));
      },
    );
  }

  void _onReceived(SessionsReceived event, Emitter<SessionState> emit) {
    final current = state;
    final sessions = _applyCounts(event.sessions);
    if (current is SessionLoaded) {
      emit(current.copyWith(sessions: sessions));
    } else {
      emit(SessionLoaded(sessions: sessions));
    }
  }

  void _onWorkoutCountsReceived(
    WorkoutCountsReceived event,
    Emitter<SessionState> emit,
  ) {
    final counts = <int, int>{};
    for (final w in event.workouts) {
      counts.update(w.sessionId, (n) => n + 1, ifAbsent: () => 1);
    }
    if (_mapsEqual(counts, _workoutCountsBySessionId)) return;
    _workoutCountsBySessionId = counts;
    final current = state;
    if (current is SessionLoaded) {
      emit(current.copyWith(sessions: _applyCounts(current.sessions)));
    }
  }

  /// Returns a list where only sessions whose `workoutCount` differs
  /// from the cached counts are replaced. When no count changed, the
  /// returned list is reference-equal to [source], so `Equatable`
  /// short-circuits and downstream `BlocBuilder`s skip rebuilding.
  List<Session> _applyCounts(List<Session> source) {
    final counts = _workoutCountsBySessionId;
    var changed = false;
    final patched = <Session>[];
    for (final s in source) {
      final next = counts[s.id] ?? 0;
      if (s.workoutCount != next) {
        patched.add(s.copyWith(workoutCount: next));
        changed = true;
      } else {
        patched.add(s);
      }
    }
    return changed ? patched : source;
  }

  bool _mapsEqual(Map<int, int> a, Map<int, int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  Future<void> _onLoad(
    LoadSessionsEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());
    final result = await _getSessions(const NoParams());
    result.fold(
      (failure) => emit(SessionError(failure)),
      (sessions) => emit(SessionLoaded(sessions: _applyCounts(sessions))),
    );
  }

  Future<void> _onGetById(
    GetSessionByIdEvent event,
    Emitter<SessionState> emit,
  ) async {
    final result = await _getSessionById(event.id);
    result.fold(
      (failure) => emit(SessionError(failure)),
      (session) => add(SessionReceived(session)),
    );
  }

  void _onSessionReceived(SessionReceived event, Emitter<SessionState> emit) {
    final current = state;
    if (current is SessionLoaded) {
      emit(current.copyWith(selectedSession: event.session));
    } else {
      emit(SessionLoaded(sessions: const [], selectedSession: event.session));
    }
  }

  Future<void> _onCreate(
    CreateSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    if (!isClosed) add(const MutationStarted());
    final result = await _createSession(
      CreateSessionParams(name: event.name, description: event.description),
    );
    if (isClosed) return;
    result.fold((failure) {
      emit(SessionError(failure));
      if (!isClosed) add(const MutationFinished());
    }, (_) {
      if (!isClosed) add(const MutationFinished());
    });
  }

  Future<void> _onUpdate(
    UpdateSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    if (!isClosed) add(const MutationStarted());
    final result = await _updateSession(
      UpdateSessionParams(
        id: event.id,
        name: event.name,
        description: event.description,
      ),
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(SessionError(failure));
        if (!isClosed) add(const MutationFinished());
      },
      (session) {
        if (!isClosed) add(SessionReceived(session));
        if (!isClosed) add(const MutationFinished());
      },
    );
  }

  Future<void> _onDelete(
    DeleteSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    if (!isClosed) add(const MutationStarted());
    final result = await _deleteSession(event.id);
    if (isClosed) return;
    result.fold((failure) {
      emit(SessionError(failure));
      if (!isClosed) add(const MutationFinished());
    }, (_) {
      if (!isClosed) add(const MutationFinished());
    });
  }

  void _onMutationStarted(MutationStarted event, Emitter<SessionState> emit) {
    final current = state;
    if (current is SessionLoaded) {
      emit(current.copyWith(isMutating: true));
    }
  }

  void _onMutationFinished(MutationFinished event, Emitter<SessionState> emit) {
    final current = state;
    if (current is SessionLoaded) {
      emit(current.copyWith(isMutating: false));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _workoutsSubscription?.cancel();
    return super.close();
  }
}
