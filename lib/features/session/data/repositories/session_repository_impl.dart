import 'dart:async';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_local_datasource.dart';

/// Concrete implementation of [SessionRepository] backed by Firestore.
///
/// All writes go through [SessionLocalDataSource] which mirrors the
/// data to Firestore directly. [sync] is optional so existing tests
/// can construct an instance without registering the sync graph.
class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl({required this.dataSource, this.sync});

  final SessionLocalDataSource dataSource;
  final SyncService? sync;

  @override
  Future<Either<Failure, List<Session>>> getSessions() async {
    return _guard(() async {
      final models = await dataSource.getAll();
      return <Session>[for (final m in models) m.toEntity()];
    });
  }

  @override
  Stream<Either<Failure, List<Session>>> watchSessions() {
    return dataSource
        .watchAll()
        .map<Either<Failure, List<Session>>>((models) {
          final list = <Session>[for (final m in models) m.toEntity()];
          return Right<Failure, List<Session>>(list);
        })
        .handleError(
          (Object error) => Left<Failure, List<Session>>(
            mapExceptionToFailure(
              error is AppException
                  ? error
                  : UnexpectedException(
                      'Failed to watch sessions',
                      cause: error,
                    ),
            ),
          ),
        );
  }

  @override
  Future<Either<Failure, Session>> getSessionById(int id) async {
    return _guard(() async {
      final all = await dataSource.getAll();
      for (final m in all) {
        if (m.id == id) return m.toEntity();
      }
      throw NotFoundException('Session $id not found');
    });
  }

  @override
  Future<Either<Failure, Map<int, Session>>> getSessionsByIds(
    List<int> ids,
  ) async {
    return _guard(() async {
      if (ids.isEmpty) return const <int, Session>{};
      final all = await dataSource.getAll();
      final wanted = ids.toSet();
      return <int, Session>{
        for (final m in all)
          if (m.id != null && wanted.contains(m.id)) m.id!: m.toEntity(),
      };
    });
  }

  @override
  Future<Either<Failure, Session>> createSession({
    required String name,
    required String description,
  }) async {
    return _guard(() async {
      final model = await dataSource.insert(
        name: name,
        description: description,
      );
      unawaited(sync?.uploadSession(model));
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, Session>> updateSession({
    required int id,
    required String name,
    required String description,
  }) async {
    return _guard(() async {
      final firestoreId = await _resolveFirestoreId(id);
      if (firestoreId == null) {
        throw NotFoundException('Session $id not found');
      }
      final model = await dataSource.update(
        id: firestoreId,
        name: name,
        description: description,
      );
      unawaited(sync?.uploadSession(model));
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteSession(int id) async {
    return _guard(() async {
      final firestoreId = await _resolveFirestoreId(id);
      if (firestoreId == null) {
        // Already gone (or never existed) — treat as success.
        return Unit.instance;
      }
      await dataSource.delete(firestoreId);
      unawaited(sync?.deleteSession(firestoreId));
      return Unit.instance;
    });
  }

  /// Resolve the Firestore document id for the session whose
  /// `hashCode`-derived int id matches [id]. Returns `null` if no
  /// session matches.
  Future<String?> _resolveFirestoreId(int id) async {
    final all = await dataSource.getAll();
    for (final m in all) {
      if (m.id == id && m.firestoreId != null) return m.firestoreId;
    }
    return null;
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      final value = await body();
      return Right(value);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (error) {
      return Left(UnexpectedFailure(message: 'Unexpected error', cause: error));
    }
  }
}