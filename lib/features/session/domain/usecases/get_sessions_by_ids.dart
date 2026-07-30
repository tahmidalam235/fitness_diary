import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// Bulk-loads sessions by id, returning a map keyed by session id.
///
/// Used by features that need to resolve session names for a list of
/// ids (e.g. the History/Calendar daily-details page).
class GetSessionsByIds extends UseCase<Map<int, Session>, List<int>> {
  const GetSessionsByIds({required this.repository});

  final SessionRepository repository;

  @override
  Future<Either<Failure, Map<int, Session>>> call(List<int> params) {
    return repository.getSessionsByIds(params);
  }
}
