import 'exceptions.dart';
import 'failure.dart';

/// Translates [AppException] instances thrown by the data layer into
/// user-facing [Failure] instances consumed by use cases and the UI.
Failure mapExceptionToFailure(AppException exception) {
  return switch (exception) {
    DatabaseException() => DatabaseFailure(
        message: exception.message,
        cause: exception.cause,
      ),
    NotFoundException() => NotFoundFailure(
        message: exception.message,
        cause: exception.cause,
      ),
    ValidationException() => ValidationFailure(
        errors: exception.errors,
        cause: exception.cause,
      ),
    UnexpectedException() => UnexpectedFailure(
        message: exception.message,
        cause: exception.cause,
      ),
  };
}