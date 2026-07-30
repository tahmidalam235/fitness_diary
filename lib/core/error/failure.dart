import 'package:equatable/equatable.dart';

/// Base type for all expected, user-facing failure modes.
sealed class Failure extends Equatable {
  const Failure({this.message = '', this.cause});

  /// Human-readable, safe-to-display description.
  final String message;

  /// Optional underlying cause (for logging only — never expose to UI).
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];
}

/// Database-layer failure (SQLite, Drift, IO errors).
final class DatabaseFailure extends Failure {
  const DatabaseFailure({super.message = 'Database error', super.cause});
}

/// Resource not found.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Not found', super.cause});
}

/// Validation failure from a use case.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required this.errors,
    super.message = 'Validation failed',
    super.cause,
  });

  /// Map of field name → error message.
  final Map<String, String> errors;

  @override
  List<Object?> get props => [message, cause, errors];
}

/// Catch-all for unexpected errors that don't fit other categories.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message = 'Unexpected error', super.cause});
}