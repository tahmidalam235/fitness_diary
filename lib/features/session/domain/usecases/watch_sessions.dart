import '../../../../core/error/failure.dart';
import '../../../../core/usecase/no_params.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// Streams all sessions, emitting on every database change.
class WatchSessions extends StreamUseCase<List<Session>, NoParams> {
  const WatchSessions({required this.repository});

  final SessionRepository repository;

  @override
  Stream<Either<Failure, List<Session>>> call(NoParams params) {
    return repository.watchSessions();
  }
}
