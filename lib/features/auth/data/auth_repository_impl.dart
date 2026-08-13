import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Resolve the account info for a given username, or null if no such
  /// account exists. Uses the public `usernames` collection as a lookup
  /// index so we can map username -> email/uid without exposing the
  /// email to the UI layer.
  Future<Map<String, dynamic>?> _infoForUsername(String username) async {
    final snap = await _firestore
        .collection('usernames')
        .doc(username.trim().toLowerCase())
        .get();
    return snap.data();
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

    try {
      // Reject usernames that are already taken.
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

      // We use the real user email for Firebase Auth so the "Forgot
      // Password" reset links actually reach their inbox.
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
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

      // Persist profile data + the username lookup index. The index
      // doc includes the email so logins can resolve username -> email
      // before hitting Firebase Auth.
      await _firestore.collection('users').doc(user.uid).set({
        'username': username.trim(),
        'displayName': displayName.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('usernames').doc(usernameKey).set({
        'uid': user.uid,
        'email': email.trim(),
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
              message: 'That email is already registered',
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
      final info = await _infoForUsername(username);
      // Use the email stored in the public index. Fallback to the legacy
      // synthesized format if the index hasn't been updated with a real
      // email yet — this ensures existing users can still log in while
      // allowing new/updated users to use the password-reset feature.
      final email =
          info?['email'] as String? ??
          '${username.trim().toLowerCase()}@fitnessdiary.local';

      if (info == null) {
        return const Left(
          AuthFailure(
            code: AuthFailureCode.invalidCredentials,
            message: 'Invalid username or password',
          ),
        );
      }

      // We have the email; sign in.
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
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
  Future<Either<Failure, Unit>> resetPassword({required String email}) async {
    final normalized = email.trim();
    if (normalized.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized)) {
      return const Left(
        AuthFailure(
          code: AuthFailureCode.invalidCredentials,
          message: 'Please enter a valid email address',
        ),
      );
    }

    // Resolve the canonical email via the public `usernames/{u}` index.
    // The index is keyed by username but we can derive a candidate
    // username from the local-part of the typed email (everything
    // before the `@`). If a matching doc exists we trust its `email`
    // field as the source of truth — this protects against stored
    // typos and matches the lookup pattern used by login(). If the
    // lookup misses we fall back to the user-typed value, preserving
    // the previous behavior.
    String resolvedEmail = normalized;
    final localPart = normalized.split('@').first;
    if (localPart.isNotEmpty) {
      try {
        final info = await _infoForUsername(localPart);
        final indexed = info?['email'] as String?;
        if (indexed != null && indexed.trim().isNotEmpty) {
          resolvedEmail = indexed.trim();
        }
      } on FirebaseException catch (e) {
        // Permission / unavailable errors here are non-fatal — we
        // just log and fall back to the typed email.
        debugPrint(
          'resetPassword: index lookup failed (${e.code}); '
          'falling back to typed email',
        );
      }
    }

    try {
      await _auth.sendPasswordResetEmail(email: resolvedEmail);
      return const Right(Unit.instance);
    } on FirebaseAuthException catch (e) {
      // Always log the Firebase response so logcat shows whether the
      // reset was actually issued — important for diagnosing cases
      // like a legacy Firebase Auth account that was created under
      // the synthesized-email flow and so never received the real
      // email at signup (Firebase returns user-not-found, our UI
      // shows success, but no email is ever sent).
      debugPrint(
        'resetPassword: ${e.code} for $resolvedEmail '
        '(typed=$normalized)',
      );
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-email' ||
          e.code == 'missing-email') {
        // Success branch to avoid leaking registered emails to the UI.
        return const Right(Unit.instance);
      }
      return const Left(
        AuthFailure(
          code: AuthFailureCode.unknown,
          message: 'Could not send reset link. Please try again.',
        ),
      );
    } catch (e, st) {
      debugPrint('resetPassword: unexpected error\n$e\n$st');
      return const Left(
        AuthFailure(
          code: AuthFailureCode.unknown,
          message: 'Could not send reset link. Please try again.',
        ),
      );
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
