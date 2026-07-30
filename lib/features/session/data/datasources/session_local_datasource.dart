import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db show SessionsCompanion;
import '../../../../core/database/daos/session_dao.dart';
import '../../../../core/error/exceptions.dart';
import '../models/session_model.dart';

/// Low-level local data source wrapping the Drift [SessionDao].
///
/// Translates raw Drift errors into [AppException] so the repository can
/// convert them into user-facing [Failure]s without coupling to Drift.
class SessionLocalDataSource {
  const SessionLocalDataSource({required this.dao});

  final SessionDao dao;

  Future<List<SessionModel>> getAll() async {
    try {
      final rows = await dao.getAllSessions();
      return <SessionModel>[
        for (final row in rows) SessionModel.fromDrift(row),
      ];
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to load sessions',
        cause: error,
      );
    }
  }

  Stream<List<SessionModel>> watchAll() {
    try {
      return dao.watchSessions().map<List<SessionModel>>(
            (rows) => <SessionModel>[
              for (final row in rows) SessionModel.fromDrift(row),
            ],
          );
    } catch (error) {
      throw DatabaseException(
        'Failed to watch sessions',
        cause: error,
      );
    }
  }

  Future<SessionModel?> getById(int id) async {
    try {
      final row = await dao.getSessionById(id);
      if (row == null) {
        throw NotFoundException('Session $id not found');
      }
      return SessionModel.fromDrift(row);
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to load session $id',
        cause: error,
      );
    }
  }

  Future<List<SessionModel>> getByIds(List<int> ids) async {
    try {
      if (ids.isEmpty) return const <SessionModel>[];
      final rows = await dao.getSessionsByIds(ids);
      return <SessionModel>[
        for (final row in rows) SessionModel.fromDrift(row),
      ];
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to load sessions by ids',
        cause: error,
      );
    }
  }

  Future<SessionModel> insert({
    required String name,
    required String description,
  }) async {
    try {
      final now = DateTime.now();
      final companion = db.SessionsCompanion.insert(
        name: name,
        description: Value(description),
        createdAt: Value(now),
        updatedAt: Value<DateTime?>(now),
      );
      final id = await dao.insertSession(companion);
      final row = await dao.getSessionById(id);
      if (row == null) {
        throw const UnexpectedException('Insert succeeded but row missing');
      }
      return SessionModel.fromDrift(row);
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to create session',
        cause: error,
      );
    }
  }

  Future<SessionModel> update({
    required int id,
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
        updatedAt: Value<DateTime?>(now),
      );
      await dao.updateSession(updated);
      return SessionModel.fromDrift(updated);
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to update session',
        cause: error,
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      await dao.deleteSession(id);
    } on AppException {
      rethrow;
    } catch (error) {
      throw DatabaseException(
        'Failed to delete session',
        cause: error,
      );
    }
  }
}