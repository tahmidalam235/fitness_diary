import 'dart:async';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_local_datasource.dart';

/// Concrete implementation of [SessionRepository] backed by the local
/// SQLite (Drift) data source.
class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl({required this.dataSource});

  final SessionLocalDataSource dataSource;

  @override
  Future<Either<Failure, List<Session>>> getSessions() async {
    return _guard(() async {
      final models = await dataSource.getAll();
      return <Session>[
        for (final m in models) m.toEntity(),
      ];
    });
  }

  @override
  Stream<Either<Failure, List<Session>>> watchSessions() {
    return dataSource.watchAll().map<Either<Failure, List<Session>>>(
      (models) {
        final list = <Session>[
          for (final m in models) m.toEntity(),
        ];
        return Right<Failure, List<Session>>(list);
      },
    ).handleError(
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
      final model = await dataSource.getById(id);
      return model!.toEntity();
    });
  }

  @override
  Future<Either<Failure, Map<int, Session>>> getSessionsByIds(
    List<int> ids,
  ) async {
    return _guard(() async {
      if (ids.isEmpty) return const <int, Session>{};
      final models = await dataSource.getByIds(ids);
      return <int, Session>{
        for (final m in models)
          if (m.id != null) m.id!: m.toEntity(),
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
      final model = await dataSource.update(
        id: id,
        name: name,
        description: description,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteSession(int id) async {
    return _guard(() async {
      await dataSource.delete(id);
      return Unit.instance;
    });
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      final value = await body();
      return Right(value);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (error) {
      return Left(
        UnexpectedFailure(message: 'Unexpected error', cause: error),
      );
    }
  }
}