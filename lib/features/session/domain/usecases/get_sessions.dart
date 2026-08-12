import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/no_params.dart';
import '../../../../core/utils/either.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// Loads all sessions (one-shot).
class GetSessions extends UseCase<List<Session>, NoParams> {
  const GetSessions({required this.repository});

  final SessionRepository repository;

  @override
  Future<Either<Failure, List<Session>>> call(NoParams params) {
    return repository.getSessions();
  }
}
