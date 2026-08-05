import 'package:drift/drift.dart';

/// Local user accounts for the on-device auth flow.
///
/// The schema v8 migration adds this table to store a single account
/// per device. Passwords are stored as PBKDF2-HMAC-SHA256 hashes with
/// a per-user random salt; the `iterations` column is kept so we can
/// upgrade the work factor in future migrations without losing
/// existing logins.
///
/// Username uniqueness is enforced via a UNIQUE INDEX created in
/// the migration (Drift's `.unique()` requires extra plumbing for
/// sqlite3; raw SQL is simpler and matches the existing migration
/// style used for `workout_log_entries.sets`).
@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get username => text().withLength(min: 3, max: 32)();

  /// Base64-encoded PBKDF2 output (32 bytes by default).
  TextColumn get passwordHash => text()();

  /// Base64-encoded random salt (16 bytes).
  TextColumn get passwordSalt => text()();

  /// PBKDF2 iteration count used for this row's hash.
  IntColumn get iterations =>
      integer().withDefault(const Constant(120000))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}