/// Base type for all expected exceptions thrown by the data layer.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType($message)';
}

final class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause});
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {required this.errors, super.cause});

  final Map<String, String> errors;
}

final class UnexpectedException extends AppException {
  const UnexpectedException(super.message, {super.cause});
}
