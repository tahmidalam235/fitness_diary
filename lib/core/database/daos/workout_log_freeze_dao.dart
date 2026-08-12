import '../../sync/sync_service.dart';
import '../../../features/history/data/models/freeze_day_model.dart';

/// Firestore-backed replacement for the old Drift `WorkoutLogFreezeDao`.
///
/// All methods delegate to [SyncService]. The return shapes are kept
/// close to the original (set/date-keyed maps, lists of `FreezeDayModel`)
/// so the streak feature, freeze page, and history repository don't need
/// to change.
class WorkoutLogFreezeDao {
  WorkoutLogFreezeDao(this._sync);

  final SyncService _sync;

  /// Inserts a freeze for [day] (idempotent on Firestore: if a freeze
  /// already exists for that day, it is overwritten with [note] /
  /// `updatedAt`). Returns the new freeze's `firestoreId` (a positive
  /// int hash for legacy-shape compatibility) or `0` if no uid.
  Future<int> insertFreeze({
    required DateTime day,
    String note = '',
    DateTime? updatedAt,
  }) async {
    final fid = await _sync.insertFreeze(day: day, note: note);
    return fid.isEmpty ? 0 : fid.hashCode;
  }

  /// Removes the freeze for the half-open range `[day, day + 1 day)`.
  Future<int> deleteFreezeForDay(DateTime day) async {
    final rows = await _sync.selectFreezesForDay(day);
    for (final row in rows) {
      if (row.firestoreId.isNotEmpty) {
        await _sync.deleteFreeze(row.firestoreId);
      }
    }
    return rows.length;
  }

  /// Returns any freeze rows for the half-open range `[day, day + 1 day)`.
  Future<List<FreezeDayModel>> selectFreezesForDay(DateTime day) =>
      _sync.selectFreezesForDay(day);

  /// Reactive stream of every frozen day, normalized to midnight local.
  Stream<Set<DateTime>> watchFrozenDays() => _sync.watchFrozenDays();

  Stream<List<FreezeDayModel>> watchFreezesInRange({
    required DateTime start,
    required DateTime end,
  }) => _sync.watchFreezesInRange(start: start, end: end);
}