import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/unit.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

/// Firebase-backed auth repository. Replaces the previous local
/// SQLite + SharedPreferences implementation.
///
/// Firebase Authentication requires an email-shaped identifier, so we
/// synthesize one from the chosen username (`{username}@fitnessdiary.local`).
/// The user-supplied email (collected at signup) is preserved in a
/// Firestore profile doc keyed by the Firebase uid, but is never used
/// to log in — login still works with just username + password.
///
/// Firestore access is gated by the rules in `firestore.rules` at the
/// project root. Deploy them via the Firebase console or with
/// `firebase deploy --only firestore:rules`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl();

  static const _emailDomain = '@fitnessdiary.local';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Map a public username to the synthesized Firebase auth email.
  static String _authEmail(String username) =>
      '${username.trim().toLowerCase()}$_emailDomain';

  /// Resolve the Firebase uid for a given username, or null if no such
  /// account exists. Uses the public `usernames` collection as a lookup
  /// index so we can map username -> uid without exposing the synthesized
  /// email to the UI layer.
  Future<String?> _uidForUsername(String username) async {
    final snap = await _firestore
        .collection('usernames')
        .doc(username.trim().toLowerCase())
        .get();
    final data = snap.data();
    if (data == null) return null;
    return data['uid'] as String?;
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

    final usernameKey = username.trim().toLowerCase();
    final authEmail = _authEmail(username);

    try {
      // Reject usernames that are already taken — we can't rely on
      // Firebase's createUserWithEmailAndPassword for this because
      // we synthesize the email from the username, so two different
      // usernames could collide on the same email only if the
      // username-collision happens first.
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(usernameKey)
          .get();
      if (usernameDoc.exists) {
        return const Left(
          AuthFailure(
            code: AuthFailureCode.usernameTaken,
            message: 'That username is already taken',
          ),
        );
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: authEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Left(
          AuthFailure(
            code: AuthFailureCode.unknown,
            message: 'Could not create account',
          ),
        );
      }

      // Persist profile data + the username->uid lookup so future
      // logins can resolve a username to its Firebase uid.
      await _firestore.collection('users').doc(user.uid).set({
        'username': username.trim(),
        'displayName': displayName.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('usernames').doc(usernameKey).set({
        'uid': user.uid,
      });

      return Right(
        AuthUser(
          id: user.uid.hashCode,
          username: username.trim(),
          createdAt: DateTime.now(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return const Left(
            AuthFailure(
              code: AuthFailureCode.usernameTaken,
              message: 'That username is already taken',
            ),
          );
        case 'weak-password':
          return Left(
            ValidationFailure(errors: {'password': 'Password is too weak'}),
          );
        case 'invalid-email':
          return const Left(
            AuthFailure(
              code: AuthFailureCode.unknown,
              message: 'Invalid email format',
            ),
          );
        default:
          return Left(
            AuthFailure(
              code: AuthFailureCode.unknown,
              message: e.message ?? 'Could not create account',
            ),
          );
      }
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
      final uid = await _uidForUsername(username);
      if (uid == null) {
        return const Left(
          AuthFailure(
            code: AuthFailureCode.invalidCredentials,
            message: 'Invalid username or password',
          ),
        );
      }

      // We have the uid; sign in with the synthesized email + password.
      final credential = await _auth.signInWithEmailAndPassword(
        email: _authEmail(username),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Left(
          AuthFailure(
            code: AuthFailureCode.invalidCredentials,
            message: 'Invalid username or password',
          ),
        );
      }

      return Right(
        AuthUser(
          id: user.uid.hashCode,
          username: username.trim(),
          createdAt: DateTime.now(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return const Left(
            AuthFailure(
              code: AuthFailureCode.invalidCredentials,
              message: 'Invalid username or password',
            ),
          );
        default:
          return Left(
            AuthFailure(
              code: AuthFailureCode.unknown,
              message: e.message ?? 'Could not sign in',
            ),
          );
      }
    } catch (e) {
      return Left(UnexpectedFailure(cause: e, message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasUser() async {
    try {
      // For a Firebase-backed app, "has user" means: is there a signed-in
      // Firebase user already on this device? Firebase persists the
      // auth token across launches, so this survives reinstalls only
      // if the user is also signed in to the device + the Firebase
      // session hasn't expired — but it works for the common case of
      // "user opened the app yesterday and is still signed in".
      return Right(_auth.currentUser != null);
    } catch (e) {
      return Left(UnexpectedFailure(cause: e, message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _auth.signOut();
      return const Right(Unit.instance);
    } catch (e) {
      return Left(UnexpectedFailure(cause: e, message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int?>> currentUserId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const Right(null);
      // Hash the uid so the rest of the app — which still treats the
      // id as an int SQLite-style key — keeps working unchanged.
      return Right(user.uid.hashCode);
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
