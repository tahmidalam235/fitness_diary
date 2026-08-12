import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../repositories/session_repository.dart';

/// Deletes a session by id. Returns `Unit` on success.
class DeleteSession extends UseCase<Unit, int> {
  const DeleteSession({required this.repository});

  final SessionRepository repository;

  @override
  Future<Either<Failure, Unit>> call(int params) {
    return repository.deleteSession(params);
  }
}
