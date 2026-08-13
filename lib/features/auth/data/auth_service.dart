import 'package:flutter/foundation.dart';

import '../../../core/di/injection.dart';
import '../../profile/data/profile_service.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

/// In-memory authentication state, backed by Firebase Auth.
///
/// Firestore is the single source of truth for user data; there is no
/// local cache to clear on logout. The router reads [isSignedIn] via
/// `refreshListenable` to redirect between login and the main shell.
class AuthService extends ChangeNotifier {
  AuthService({
    required AuthRepository repository,
    ProfileService? profileService,
  }) : _repository = repository,
       _profileService = profileService;

  final AuthRepository _repository;
  final ProfileService? _profileService;

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// True iff a user is signed in on this device.
  bool get isSignedIn => _currentUser != null;

  /// Reads the persisted session id (if any) so the router knows
  /// the initial auth state before the user taps anything.
  Future<void> load() async {
    if (_loaded) return;
    final idResult = await _repository.currentUserId();
    final id = idResult.getOrElse((_) => null);
    if (id != null) {
      _currentUser = AuthUser(
        id: id,
        username: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
    _loaded = true;
    notifyListeners();
  }

  Future<AuthResult> signup({
    required String username,
    required String password,
    required String confirmPassword,
    required String displayName,
    required String email,
  }) async {
    final result = await _repository.signup(
      username: username,
      password: password,
      confirmPassword: confirmPassword,
      displayName: displayName,
      email: email,
    );
    return result.fold((failure) => AuthResult.failure(failure), (user) async {
      _currentUser = user;
      _seedProfile(name: displayName, email: email);
      // Firestore is the source of truth — no local restore needed.
      notifyListeners();
      return AuthResult.success(user);
    });
  }

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final result = await _repository.login(
      username: username,
      password: password,
    );
    return result.fold((failure) => AuthResult.failure(failure), (user) async {
      _currentUser = user;
      // Firestore is the source of truth — every page subscribes to
      // the relevant collection on first render, so the UI populates
      // from cloud without any explicit restore step.
      notifyListeners();
      return AuthResult.success(user);
    });
  }

  /// Sends a Firebase Authentication password-reset request for the
  /// account with the given [email]. Does not change the current
  /// session — the caller stays signed out until they reset and log
  /// back in with the new password.
  Future<AuthResult> resetPassword({required String email}) async {
    final result = await _repository.resetPassword(email: email);
    return result.fold(
      (failure) => AuthResult.failure(failure),
      (_) => AuthResult.success(null),
    );
  }

  /// Clears the session by signing the user out of Firebase Auth.
  /// No local cache to clear (Firestore is the only source of truth
  /// and is keyed by uid, so the next sign-in gets a fresh collection
  /// view).
  Future<AuthResult> logout() async {
    final result = await _repository.logout();
    return result.fold((failure) => AuthResult.failure(failure), (_) {
      _currentUser = null;
      notifyListeners();
      return AuthResult.success(null);
    });
  }

  /// Push the new identity into [ProfileService] so the drawer /
  /// profile page update without a manual reload. Looks up the
  /// service lazily via getIt to avoid a circular import during
  /// DI bootstrap.
  void _seedProfile({required String name, required String email}) {
    try {
      final svc = _profileService ?? getIt<ProfileService>();
      svc.updateName(name);
      svc.updateEmail(email);
    } catch (_) {
      // If ProfileService isn't registered yet, the next page that
      // reads it will load from SharedPreferences directly.
    }
  }
}

/// Tagged result type so the UI can branch on success vs. failure
/// without re-wrapping Either.
class AuthResult {
  const AuthResult._({this.user, this.failure});

  factory AuthResult.success(AuthUser? user) => AuthResult._(user: user);

  factory AuthResult.failure(Object failure) => AuthResult._(failure: failure);

  final AuthUser? user;
  final Object? failure;

  bool get isSuccess => failure == null;
}
