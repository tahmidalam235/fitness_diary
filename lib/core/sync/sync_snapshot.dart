import '../../features/history/data/models/freeze_day_model.dart';
import '../../features/profile/data/profile_service.dart';
import '../../features/session/data/models/session_model.dart';
import '../../features/workout/data/models/workout_model.dart';
import '../../features/workout_log/data/models/workout_log_entry_model.dart';
import '../../features/workout_log/data/models/workout_log_model.dart';

/// User-tunable settings synced as a single Firestore doc.
class SettingsSnapshot {
  const SettingsSnapshot({
    required this.unit,
    required this.notifications,
    required this.weeklyReports,
    required this.reminderHour,
    required this.reminderMinute,
  });

  factory SettingsSnapshot.fromJson(Map<String, dynamic> json) =>
      SettingsSnapshot(
        unit: (json['unit'] as String?) ?? 'kg',
        notifications: (json['notifications'] as bool?) ?? true,
        weeklyReports: (json['weeklyReports'] as bool?) ?? false,
        reminderHour: (json['reminderHour'] as int?) ?? 19,
        reminderMinute: (json['reminderMinute'] as int?) ?? 0,
      );

  final String unit; // 'kg' or 'lb'
  final bool notifications;
  final bool weeklyReports;
  final int reminderHour;
  final int reminderMinute;

  Map<String, dynamic> toJson() => {
    'unit': unit,
    'notifications': notifications,
    'weeklyReports': weeklyReports,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
  };
}

/// A bag of every row we currently have in Firestore. Returned by
/// [SyncService.downloadAll].
///
/// `null` profile/settings means "no doc exists in Firestore yet" (a
/// brand-new user). Empty lists are valid and mean "user has no rows
/// of this kind yet".
class SyncSnapshot {
  const SyncSnapshot({
    required this.profile,
    required this.settings,
    required this.sessions,
    required this.workouts,
    required this.sessionWorkouts,
    required this.workoutLogs,
    required this.workoutLogEntries,
    required this.freezes,
  });

  final UserProfile? profile;
  final SettingsSnapshot? settings;
  final List<SessionModel> sessions;

  /// Master [Workout] rows. The restore path needs these to re-link
  /// session_workouts back to their master.
  final List<WorkoutModel> workouts;

  /// Per-session join rows. Kept separate from [workouts] so the
  /// restore service can insert them in the right FK order.
  final List<WorkoutModel> sessionWorkouts;

  final List<WorkoutLogModel> workoutLogs;
  final List<WorkoutLogEntryModel> workoutLogEntries;
  final List<FreezeDayModel> freezes;

  bool get isEmpty =>
      profile == null &&
      settings == null &&
      sessions.isEmpty &&
      workouts.isEmpty &&
      sessionWorkouts.isEmpty &&
      workoutLogs.isEmpty &&
      workoutLogEntries.isEmpty &&
      freezes.isEmpty;
}
