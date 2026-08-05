import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/users_table.dart';

part 'auth_dao.g.dart';

/// Data-access object for the [Users] table.
///
/// Lookups are by username (the login identifier). The `count` method
/// exists so the router can decide between `/signup` and `/login`
/// on first launch without doing a full scan.
@DriftAccessor(tables: [Users])
class AuthDao extends DatabaseAccessor<AppDatabase> with _$AuthDaoMixin {
  AuthDao(super.db);

  /// Returns the user row with the given username, or null if none.
  /// Used by both signup (uniqueness check) and login (credential
  /// verification).
  Future<User?> findByUsername(String username) {
    return (select(users)..where((tbl) => tbl.username.equals(username)))
        .getSingleOrNull();
  }

  /// Returns the user with the given id, or null if deleted.
  Future<User?> findById(int id) {
    return (select(users)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts a new user row. Returns the auto-generated id.
  Future<int> insertUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  /// How many users are on this device. Should always be 0 or 1 since
  /// the auth flow is single-user, but kept generic so future
/// multi-account support is a config change rather than a schema
  /// change.
  Future<int> count() async {
    final all = await select(users).get();
    return all.length;
  }
}