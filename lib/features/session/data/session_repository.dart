import '../domain/session_entity.dart';

class SessionRepository {
  final List<SessionEntity> _sessions = [];

  List<SessionEntity> getSessions() {
    return List.unmodifiable(_sessions);
  }

  void addSession(SessionEntity session) {
    _sessions.add(session);
  }

  void deleteSession(int id) {
    _sessions.removeWhere((e) => e.id == id);
  }
}
