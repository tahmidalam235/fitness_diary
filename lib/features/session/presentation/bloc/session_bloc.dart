import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/daos/session_dao.dart';
import 'session_event.dart';
import 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc(this._dao) : super(const SessionState()) {
    on<LoadSessions>(_loadSessions);
    on<AddSession>(_addSession);
    on<DeleteSession>(_deleteSession);
  }

  final SessionDao _dao;

  Future<void> _loadSessions(
    LoadSessions event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final sessions = await _dao.getAllSessions();

    emit(state.copyWith(sessions: sessions, isLoading: false));
  }

  Future<void> _addSession(AddSession event, Emitter<SessionState> emit) async {
    await _dao.insertSession(event.toCompanion());

    add(const LoadSessions());
  }

  Future<void> _deleteSession(
    DeleteSession event,
    Emitter<SessionState> emit,
  ) async {
    await _dao.deleteSession(event.id);

    add(const LoadSessions());
  }
}
