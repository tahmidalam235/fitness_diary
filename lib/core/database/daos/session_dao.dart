import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sessions_table.dart';

part 'session_dao.g.dart';

@DriftAccessor(tables: [Sessions])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.db);

  Future<List<Session>> getAllSessions() {
    return select(sessions).get();
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
