import '../../../../core/database/daos/workout_log_freeze_dao.dart';

/// Firestore-backed adapter for the freeze feature.
///
/// Thin wrapper over [WorkoutLogFreezeDao] that exposes a date-only
/// `Set<DateTime>` for the streak calculator.
class FreezeLocalDataSource {
  const FreezeLocalDataSource({required this.dao});

  final WorkoutLogFreezeDao dao;

  Stream<Set<DateTime>> watchFrozenDays() => dao.watchFrozenDays();

  Future<int> insertFreeze({required DateTime day, String note = ''}) {
    return dao.insertFreeze(day: day, note: note);
  }

  Future<int> deleteFreezeForDay(DateTime day) => dao.deleteFreezeForDay(day);
}