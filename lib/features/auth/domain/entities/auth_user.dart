import 'package:equatable/equatable.dart';

/// Domain entity for a local auth account.
///
/// Holds only the fields the UI / domain layer cares about. Password
/// material (hash, salt, iterations) lives in the data layer and
/// never crosses this boundary.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.username,
    required this.createdAt,
    this.email,
  });

  final int id;
  final String username;
  final DateTime createdAt;

  /// The exact email address the user originally registered with.
  ///
  /// Held alongside [username] / [createdAt] so the Profile page can
  /// always reflect the value the user typed at signup, regardless
  /// of whether the local cache (SharedPreferences) is present or
  /// stale. Optional only because the field is rarely observed in
  /// tests where constructing a bare AuthUser is convenient.
  final String? email;

  @override
  List<Object?> get props => [id, username, createdAt, email];
}
