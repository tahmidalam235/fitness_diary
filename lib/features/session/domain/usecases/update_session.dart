import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

class UpdateSessionParams {
  const UpdateSessionParams({
    required this.id,
    required this.name,
    this.description = '',
  });

  final int id;
  final String name;
  final String description;
}

/// Updates an existing session's name and description.
///
/// Validates name length (2–60 chars). The repository is responsible
/// for setting `updatedAt = now()`.
class UpdateSession extends UseCase<Session, UpdateSessionParams> {
  const UpdateSession({required this.repository});

  final SessionRepository repository;

  @override
  Future<Either<Failure, Session>> call(UpdateSessionParams params) {
    final trimmedName = params.name.trim();
    if (trimmedName.length < 2) {
      return Future.value(
        const Left(
          ValidationFailure(
            message: 'Session name must be at least 2 characters',
            errors: {'name': 'Session name must be at least 2 characters'},
          ),
        ),
      );
    }
    if (trimmedName.length > 60) {
      return Future.value(
        const Left(
          ValidationFailure(
            message: 'Session name must be at most 60 characters',
            errors: {'name': 'Session name must be at most 60 characters'},
          ),
        ),
      );
    }

    return repository.updateSession(
      id: params.id,
      name: trimmedName,
      description: params.description.trim(),
    );
  }
}
