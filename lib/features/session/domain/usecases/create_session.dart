import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// Parameters accepted by [CreateSession].
class CreateSessionParams {
  const CreateSessionParams({required this.name, this.description = ''});

  final String name;
  final String description;
}

/// Creates a new workout session. Validates [name] length (2–60 chars).
class CreateSession extends UseCase<Session, CreateSessionParams> {
  const CreateSession({required this.repository});

  final SessionRepository repository;

  @override
  Future<Either<Failure, Session>> call(CreateSessionParams params) {
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

    return repository.createSession(
      name: trimmedName,
      description: params.description.trim(),
    );
  }
}
