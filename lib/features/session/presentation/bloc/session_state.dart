import '../../../../core/database/app_database.dart';

class SessionState {
  const SessionState({this.sessions = const [], this.isLoading = false});

  final List<Session> sessions;
  final bool isLoading;

  SessionState copyWith({List<Session>? sessions, bool? isLoading}) {
    return SessionState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
