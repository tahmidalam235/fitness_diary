import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/workout_log_freeze_dao.dart';

/// Low-level data source for the freeze feature.
///
/// Thin wrapper over [WorkoutLogFreezeDao] that exposes a date-only
/// `Set<DateTime>` for the streak calculator. Mirrors the layering used
/// by `HistoryLocalDataSource`.
class FreezeLocalDataSource {
  const FreezeLocalDataSource({required this.dao});

  final WorkoutLogFreezeDao dao;

  Stream<Set<DateTime>> watchFrozenDays() {
    return dao.watchFrozenDays();
  }

  Future<int> insertFreeze({
    required DateTime day,
    String note = '',
  }) {
    return dao.insertFreeze(
      WorkoutLogFreezesCompanion(
        day: Value(day),
        note: Value(note),
      ),
    );
  }

  Future<int> deleteFreezeForDay(DateTime day) {
    return dao.deleteFreezeForDay(day);
  }
}
