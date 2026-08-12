import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../entities/session.dart';

/// Domain contract for session persistence.
///
/// All methods return [Either] so failures are explicit. The data layer
/// (a concrete implementation under `data/repositories/`) is responsible
/// for translating exceptions into [Failure]s.
abstract class SessionRepository {
  Future<Either<Failure, List<Session>>> getSessions();

  Stream<Either<Failure, List<Session>>> watchSessions();

  Future<Either<Failure, Session>> getSessionById(int id);

  /// Bulk lookup by id — returns a map keyed by session id for callers
  /// that want to resolve names without N round trips.
  Future<Either<Failure, Map<int, Session>>> getSessionsByIds(List<int> ids);

  Future<Either<Failure, Session>> createSession({
    required String name,
    required String description,
  });

  Future<Either<Failure, Session>> updateSession({
    required int id,
    required String name,
    required String description,
  });

  Future<Either<Failure, Unit>> deleteSession(int id);
}
