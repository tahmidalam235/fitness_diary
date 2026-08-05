import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/auth_dao.dart';
import '../../../core/error/failure.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/unit.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';
import 'password_hasher.dart';

/// SQLite + SharedPreferences-backed auth repository. Passwords are
/// salted + hashed via [PasswordHasher] before insertion; the
/// plaintext is never written to disk or shared preferences.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthDao dao,
    SharedPreferences? prefs,
  })  : _dao = dao,
        _prefs = prefs;

  final AuthDao _dao;
  SharedPreferences? _prefs;

  static const _kAuthUserId = 'auth_user_id';

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<Either<Failure, AuthUser>> signup({
    required String username,
    required String password,
    required String confirmPassword,
    required String displayName,
    required String email,
  }) async {
    final errors = _validateSignup(
      username: username,
      password: password,
      confirmPassword: confirmPassword,
      displayName: displayName,
      email: email,
    );
    if (errors.isNotEmpty) {
      return Left(ValidationFailure(errors: errors));
    }

    try {
      final existing = await _dao.findByUsername(username);
      if (existing != null) {
        return const Left(
          AuthFailure(
            code: AuthFailureCode.usernameTaken,
            message: 'That username is already taken',
          ),
        );
      }

      final hashed = PasswordHasher.hash(password);
      final id = await _dao.insertUser(
        UsersCompanion(
          username: Value(username),
          passwordHash: Value(hashed.hashB64),
          passwordSalt: Value(hashed.saltB64),
          iterations: Value(hashed.iterations),
        ),
      );

      final prefs = await _getPrefs();
      await prefs.setInt(_kAuthUserId, id);

      return Right(AuthUser(
        id: id,
        username: username,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      return Left(UnexpectedFailure(cause: e, message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> login({
    required String username,
    required String password,
  }) async {
    try {
      final user = await _dao.findByUsername(username);
      if (user == null) {
        return const Left(
          AuthFailure(
            code: AuthFailureCode.invalidCredentials,
            message: 'Invalid username or password',
          ),
        );
      }

      final ok = PasswordHasher.verify(
        password: password,
        hashed: HashedPassword(
          hashB64: user.passwordHash,
          saltB64: user.passwordSalt,
          iterations: user.iterations,
        ),
      );
      if (!ok) {
        return const Left(
          AuthFailure(
            code: AuthFailureCode.invalidCredentials,
            message: 'Invalid username or password',
          ),
        );
      }

      final prefs = await _getPrefs();
      await prefs.setInt(_kAuthUserId, user.id);

      return Right(AuthUser(
        id: user.id,
        username: user.username,
        createdAt: user.createdAt,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(cause: e, message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasUser() async {
    try {
      final count = await _dao.count();
      return Right(count > 0);
    } catch (e) {
      return Left(UnexpectedFailure(cause: e, message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_kAuthUserId);
      return const Right(Unit.instance);
    } catch (e) {
      return Left(UnexpectedFailure(cause: e, message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int?>> currentUserId() async {
    try {
      final prefs = await _getPrefs();
      return Right(prefs.getInt(_kAuthUserId));
    } catch (e) {
      return Left(UnexpectedFailure(cause: e, message: e.toString()));
    }
  }

  /// Pure validator for the signup form. Returns a map of
  /// field → message. Empty map = valid.
  Map<String, String> _validateSignup({
    required String username,
    required String password,
    required String confirmPassword,
    required String displayName,
    required String email,
  }) {
    final errors = <String, String>{};

    final u = username.trim();
    if (u.isEmpty) {
      errors['username'] = 'Required';
    } else if (u.length < 3 || u.length > 32) {
      errors['username'] = '3–32 characters';
    } else if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(u)) {
      errors['username'] = 'Letters, numbers, and underscores only';
    }

    if (password.length < 6) {
      errors['password'] = 'At least 6 characters';
    }
    if (confirmPassword != password) {
      errors['confirmPassword'] = 'Passwords do not match';
    }
    if (displayName.trim().isEmpty) {
      errors['displayName'] = 'Required';
    }

    final e = email.trim();
    if (e.isEmpty) {
      errors['email'] = 'Required';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      errors['email'] = 'Enter a valid email';
    }

    return errors;
  }
}