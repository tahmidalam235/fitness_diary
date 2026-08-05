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
  });

  final int id;
  final String username;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, username, createdAt];
}