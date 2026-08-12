/// Firestore path constants for cloud backup.
///
/// All user data lives under `users/{uid}/…`. The path is keyed by the
/// Firebase Auth uid (NOT the local Drift `int id`, which is per-device).
///
/// Doc ids inside each subcollection are the row's `firestoreId` (a v4
/// UUID assigned at insert time). This lets us round-trip a row from
/// Firestore back into a freshly-installed Drift database without id
/// collisions.
class FirestorePaths {
  const FirestorePaths._();

  /// Root collection for every user's backup data.
  static const String users = 'users';

  /// Subcollection: per-user profile (single doc, id = 'profile').
  static const String profile = 'profile';

  /// Subcollection: every [Session] template row.
  static const String sessions = 'sessions';

  /// Subcollection: master [Workout] catalog rows (exercise names).
  static const String workouts = 'workouts';

  /// Subcollection: [SessionWorkout] join rows (per-session defaults).
  static const String sessionWorkouts = 'sessionWorkouts';

  /// Subcollection: [WorkoutLog] rows (per-day session snapshots).
  static const String workoutLogs = 'workoutLogs';

  /// Subcollection: [WorkoutLogEntry] rows (per-set per-day records).
  static const String workoutLogEntries = 'workoutLogEntries';

  /// Subcollection: [WorkoutLogFreeze] rows (streak-freeze markers).
  static const String freezes = 'freezes';

  /// Subcollection: per-user settings (single doc, id = 'settings').
  static const String settings = 'settings';

  /// Index collection that maps username → uid (used by Auth only).
  static const String usernames = 'usernames';

  /// Builds the path to a user's data root.
  static String userRoot(String uid) => '$users/$uid';

  /// Builds the path to a single doc inside a subcollection.
  static String doc({
    required String uid,
    required String subcollection,
    required String docId,
  }) => '$users/$uid/$subcollection/$docId';
}
