import '../../sync/firestore_id.dart';
import '../../sync/sync_service.dart';
import '../../../features/session/data/models/session_model.dart';

/// Firestore-backed replacement for the old Drift `SessionDao`.
///
/// Method signatures are kept identical to the Drift DAO so the local
/// data sources can switch to a `SyncService` field without changing
/// the rest of the call shape. Every read returns parsed
/// [SessionModel]s; every write goes through [SyncService].
class SessionDao {
  SessionDao(this._sync);

  final SyncService _sync;

  Future<List<SessionModel>> getAllSessions() async {
    return _sync.watchSessions().first;
  }

  Stream<List<SessionModel>> watchSessions() => _sync.watchSessions();

  Future<SessionModel?> getSessionById(String firestoreId) =>
      _sync.getSessionById(firestoreId);

  Future<SessionModel?> findSessionByFirestoreId(String fid) =>
      _sync.findSessionByFirestoreId(fid);

  Future<List<SessionModel>> getSessionsByIds(List<String> fids) =>
      _sync.getSessionsByIds(fids);

  /// Inserts (uploads) a new session to Firestore. The model must
  /// already carry a fresh `firestoreId` — this method does not stamp
  /// one itself, so the caller can decide on the id format.
  Future<int> insertSession(SessionModel model) async {
    final fid = model.firestoreId ?? newFirestoreId();
    await _sync.uploadSession(model.copyWith(firestoreId: fid));
    return 1;
  }

  Future<bool> updateSession(SessionModel model) async {
    await _sync.uploadSession(model);
    return true;
  }

  Future<int> deleteSession(String firestoreId) async {
    await _sync.deleteSession(firestoreId);
    return 1;
  }
}

extension on SessionModel {
  SessionModel copyWith({String? firestoreId}) {
    return SessionModel(
      id: id,
      name: name,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
      workoutCount: workoutCount,
      firestoreId: firestoreId ?? this.firestoreId,
    );
  }
}