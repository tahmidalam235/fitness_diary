import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// Loads a single session by id.
class GetSessionById extends UseCase<Session, int> {
  const GetSessionById({required this.repository});

  final SessionRepository repository;

  @override
  Future<Either<Failure, Session>> call(int params) {
    return repository.getSessionById(params);
  }
}