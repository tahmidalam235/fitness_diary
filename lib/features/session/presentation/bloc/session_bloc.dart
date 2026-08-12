import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/no_params.dart';
import '../../../../core/utils/either.dart';
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
  }) : _getSessions = getSessions,
       _watchSessions = watchSessions,
       _getSessionById = getSessionById,
       _createSession = createSession,
       _updateSession = updateSession,
       _deleteSession = deleteSession,
       super(const SessionInitial()) {
    on<WatchSessionsEvent>(_onWatch);
    on<SessionsReceived>(_onReceived);
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

  StreamSubscription<Either<Failure, List<Session>>>? _subscription;

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
  }

  void _onReceived(SessionsReceived event, Emitter<SessionState> emit) {
    final current = state;
    if (current is SessionLoaded) {
      emit(current.copyWith(sessions: event.sessions));
    } else {
      emit(SessionLoaded(sessions: event.sessions));
    }
  }

  Future<void> _onLoad(
    LoadSessionsEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());
    final result = await _getSessions(const NoParams());
    result.fold(
      (failure) => emit(SessionError(failure)),
      (sessions) => emit(SessionLoaded(sessions: sessions)),
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
    return super.close();
  }
}
