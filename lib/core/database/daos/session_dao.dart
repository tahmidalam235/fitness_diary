import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sessions_table.dart';

part 'session_dao.g.dart';

/// Data-access object for the [Sessions] table.
@DriftAccessor(tables: [Sessions])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.db);

  /// Fetches all sessions ordered by most recently updated first.
  Future<List<Session>> getAllSessions() {
    return (select(sessions)
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.updatedAt),
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .get();
  }

  /// Reactive stream of all sessions, ordered by most recently updated.
  Stream<List<Session>> watchSessions() {
    return (select(sessions)
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.updatedAt),
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .watch();
  }

  Future<Session?> getSessionById(int id) {
    return (select(sessions)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Fetches multiple sessions by id in one round trip. Empty ids return
  /// an empty list. Used by history/day-details to resolve session names
  /// without N queries.
  Future<List<Session>> getSessionsByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value(const <Session>[]);
    return (select(sessions)..where((tbl) => tbl.id.isIn(ids))).get();
  }

  Future<int> insertSession(SessionsCompanion session) {
    return into(sessions).insert(session);
  }

  Future<bool> updateSession(Session session) {
    return update(sessions).replace(session);
  }

  Future<int> deleteSession(int id) {
    return (delete(sessions)..where((tbl) => tbl.id.equals(id))).go();
  }
}