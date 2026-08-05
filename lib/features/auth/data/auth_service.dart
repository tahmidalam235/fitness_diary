import 'package:flutter/foundation.dart';

import '../../../core/di/injection.dart';
import '../../profile/data/profile_service.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

/// In-memory + DB-backed authentication state.
///
/// Registered as an eager singleton so [GoRouter] can wire it as a
/// `refreshListenable` and react to login/logout events. Listeners
/// get notified on every state change so the drawer, profile page,
/// and router redirect all update at once.
class AuthService extends ChangeNotifier {
  AuthService({
    required AuthRepository repository,
    ProfileService? profileService,
  })  : _repository = repository,
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
      // We don't load the full AuthUser here — the router only
      // needs to know if a session exists. Full profile is
      // rehydrated on signup/login.
      _currentUser = AuthUser(
        id: id,
        username: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
    _loaded = true;
    notifyListeners();
  }

  /// Creates a new account. On success, seeds [ProfileService] with
  /// the chosen name + email so the drawer / profile page show the
  /// new identity without an extra step.
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
    return result.fold(
      (failure) => AuthResult.failure(failure),
      (user) {
        _currentUser = user;
        _seedProfile(name: displayName, email: email);
        notifyListeners();
        return AuthResult.success(user);
      },
    );
  }

  /// Verifies credentials. On success, seeds the profile from the
  /// last-known name/email so the drawer / profile page show the
  /// logged-in user's identity.
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final result = await _repository.login(
      username: username,
      password: password,
    );
    return result.fold(
      (failure) => AuthResult.failure(failure),
      (user) {
        _currentUser = user;
        notifyListeners();
        return AuthResult.success(user);
      },
    );
  }

  /// Clears the session. Profile name/email remain populated so the
  /// next login shows the same identity.
  Future<AuthResult> logout() async {
    final result = await _repository.logout();
    return result.fold(
      (failure) => AuthResult.failure(failure),
      (_) {
        _currentUser = null;
        notifyListeners();
        return AuthResult.success(null);
      },
    );
  }

  /// Push the new identity into [ProfileService] so the drawer /
  /// profile page update without a manual reload. Looks up the
  /// service lazily via getIt to avoid a circular import during
  /// DI bootstrap.
  void _seedProfile({required String name, required String email}) {
    try {
      final svc = _profileService ?? getIt<ProfileService>();
      // Fire-and-forget — ProfileService has its own persistence.
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

  factory AuthResult.success(AuthUser? user) =>
      AuthResult._(user: user);

  factory AuthResult.failure(Object failure) =>
      AuthResult._(failure: failure);

  final AuthUser? user;
  final Object? failure;

  bool get isSuccess => failure == null;
}