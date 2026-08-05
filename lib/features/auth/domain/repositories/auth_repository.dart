import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../entities/auth_user.dart';

/// Domain contract for local-only authentication.
///
/// All methods return [Either] so failures are explicit. The data
/// layer is responsible for translating exceptions into [Failure]s.
abstract class AuthRepository {
  /// Creates a new local account. Persists the session id in
  /// SharedPreferences so subsequent launches can find the user
  /// without prompting. Throws [ValidationFailure] for empty /
  /// malformed inputs, [AuthFailure] with
  /// [AuthFailureCode.usernameTaken] if the username is taken.
  Future<Either<Failure, AuthUser>> signup({
    required String username,
    required String password,
    required String confirmPassword,
    required String displayName,
    required String email,
  });

  /// Verifies credentials and persists the session id. Returns
  /// [AuthFailure] with [AuthFailureCode.invalidCredentials] on
  /// mismatched username or password.
  Future<Either<Failure, AuthUser>> login({
    required String username,
    required String password,
  });

  /// True iff at least one account exists on this device. The
  /// router uses this to decide between `/signup` (first launch)
  /// and `/login` (returning user).
  Future<Either<Failure, bool>> hasUser();

  /// Clears the session id in SharedPreferences. Does NOT delete
  /// the user row, profile data, workout history, or settings — the
  /// user can log back in and pick up right where they left off.
  Future<Either<Failure, Unit>> logout();

  /// Returns the persisted session id, or null if no user is signed
  /// in on this device.
  Future<Either<Failure, int?>> currentUserId();
}