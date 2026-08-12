import '../../../../core/database/daos/session_dao.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/firestore_id.dart';
import '../models/session_model.dart';

/// Firestore-backed adapter for the session feature.
///
/// Internally delegates to [SessionDao] (which talks to Firestore via
/// [SyncService]). Method signatures match the original Drift-backed
/// data source so the repository layer doesn't change.
class SessionLocalDataSource {
  const SessionLocalDataSource({required this.dao});

  final SessionDao dao;

  Future<List<SessionModel>> getAll() async {
    try {
      return await dao.getAllSessions();
    } catch (error) {
      throw DatabaseException('Failed to load sessions', cause: error);
    }
  }

  Stream<List<SessionModel>> watchAll() {
    try {
      return dao.watchSessions();
    } catch (error) {
      throw DatabaseException('Failed to watch sessions', cause: error);
    }
  }

  Future<SessionModel?> getById(String id) async {
    try {
      final row = await dao.getSessionById(id);
      return row;
    } catch (error) {
      throw DatabaseException('Failed to load session $id', cause: error);
    }
  }

  Future<List<SessionModel>> getByIds(List<String> ids) async {
    try {
      if (ids.isEmpty) return const <SessionModel>[];
      return await dao.getSessionsByIds(ids);
    } catch (error) {
      throw DatabaseException('Failed to load sessions by ids', cause: error);
    }
  }

  Future<SessionModel> insert({
    required String name,
    required String description,
  }) async {
    try {
      final now = DateTime.now();
      final fid = newFirestoreId();
      final model = SessionModel(
        id: fid.hashCode,
        name: name,
        description: description,
        createdAt: now,
        updatedAt: now,
        workoutCount: 0,
        firestoreId: fid,
      );
      await dao.insertSession(model);
      // Re-read so the caller's model carries any cloud-side
      // canonicalization.
      final fresh = await dao.getSessionById(fid);
      return fresh ?? model;
    } catch (error) {
      throw DatabaseException('Failed to create session', cause: error);
    }
  }

  Future<SessionModel> update({
    required String id,
    required String name,
    required String description,
  }) async {
    try {
      final existing = await dao.getSessionById(id);
      if (existing == null) {
        throw NotFoundException('Session $id not found');
      }
      final now = DateTime.now();
      final updated = existing.copyWith(
        name: name,
        description: description,
        updatedAt: now,
      );
      await dao.updateSession(updated);
      return updated;
    } catch (error) {
      throw DatabaseException('Failed to update session', cause: error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await dao.deleteSession(id);
    } catch (error) {
      throw DatabaseException('Failed to delete session', cause: error);
    }
  }
}

extension on SessionModel {
  SessionModel copyWith({
    String? name,
    String? description,
    DateTime? updatedAt,
  }) {
    return SessionModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workoutCount: workoutCount,
      firestoreId: firestoreId,
    );
  }
}