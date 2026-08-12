import '../../../features/workout_log/data/models/workout_log_entry_model.dart';
import '../../../features/workout_log/data/models/workout_log_model.dart';
import '../../sync/firestore_id.dart';
import '../../sync/sync_service.dart';

/// Firestore-backed replacement for the old Drift `WorkoutLogDao`.
///
/// Preserves the **same public method signatures** the widgets and
/// repositories already depend on, but every method delegates to
/// [SyncService] which talks directly to Cloud Firestore. There is no
/// local SQLite mirror.
///
/// Returned `WorkoutLogModel` / `WorkoutLogEntryModel` objects carry
/// both `firestoreId` (the Firestore document id, source of truth) and
/// `id` (derived from `firestoreId.hashCode` for backwards-compat with
/// the existing int-keyed domain entities).
class WorkoutLogDao {
  WorkoutLogDao(this._sync);

  final SyncService _sync;

  // ---------------------------------------------------------------------------
  // Logs
  // ---------------------------------------------------------------------------

  /// Inserts (uploads) a new workout log to Firestore. Returns a
  /// placeholder `1` so the call shape matches the old Drift API.
  Future<int> insertLog(WorkoutLogModel model) async {
    final fid = model.firestoreId ?? newFirestoreId();
    await _sync.uploadWorkoutLog(model.copyWith(firestoreId: fid));
    return 1;
  }

  Future<bool> updateLog(WorkoutLogModel model) async {
    await _sync.uploadWorkoutLog(model);
    return true;
  }

  Future<int> deleteLog(String firestoreId) async {
    await _sync.deleteWorkoutLog(firestoreId);
    return 1;
  }

  Future<WorkoutLogModel?> getLogById(String firestoreId) =>
      _sync.getLogById(firestoreId);

  Stream<List<WorkoutLogModel>> watchAllLogs() => _sync.watchAllLogs();

  Future<WorkoutLogModel?> findLogForDay({
    required String sessionFirestoreId,
    required DateTime day,
  }) => _sync.findLogForDay(sessionFid: sessionFirestoreId, day: day);

  Stream<WorkoutLogModel?> watchLogForDay({
    required String sessionFirestoreId,
    required DateTime day,
  }) {
    return _sync.watchLogsForDay(day).map((logs) {
      for (final log in logs) {
        if (log.sessionFirestoreId == sessionFirestoreId) return log;
      }
      return null;
    });
  }

  /// All logs whose `performedAt` falls inside the half-open range
  /// `[start, end)`.
  Stream<List<WorkoutLogModel>> watchLogsInRange({
    required DateTime start,
    required DateTime end,
  }) => _sync.watchLogsInRange(start: start, end: end);

  /// Every log performed on the given calendar day.
  Stream<List<WorkoutLogModel>> watchLogsForDay(DateTime day) =>
      _sync.watchLogsForDay(day);

  /// All entries for every log performed on the given calendar day,
  /// joined with each parent log's `firestoreId` so the UI can group by
  /// log id.
  Stream<List<DayEntryRow>> watchEntriesForDay(DateTime day) =>
      _sync.watchEntriesForDay(day);

  // ---------------------------------------------------------------------------
  // Entries
  // ---------------------------------------------------------------------------

  Future<int> insertEntry(WorkoutLogEntryModel model) async {
    final fid = model.firestoreId ?? newFirestoreId();
    await _sync.uploadWorkoutLogEntry(model.copyWith(firestoreId: fid));
    return 1;
  }

  Future<bool> updateEntry(WorkoutLogEntryModel model) async {
    await _sync.uploadWorkoutLogEntry(model);
    return true;
  }

  Future<int> deleteEntry(String firestoreId) async {
    await _sync.deleteWorkoutLogEntry(firestoreId);
    return 1;
  }

  Future<List<WorkoutLogEntryModel>> getEntriesForLog(String logFid) =>
      _sync.getEntriesForLog(logFid);

  /// Same as [getEntriesForLog] but accepts the int hash form
  /// (`WorkoutLog.id`) so the existing UI code that only has the int
  /// doesn't need to know about Firestore ids. Internally scans all
  /// logs to translate the int hash back to its firestoreId.
  Future<List<WorkoutLogEntryModel>> getEntriesForLogById(int logId) async {
    final matched = await _resolveLogById(logId);
    if (matched == null) return const <WorkoutLogEntryModel>[];
    return _sync.getEntriesForLog(matched);
  }

  Future<WorkoutLogEntryModel?> getEntryById(String firestoreId) =>
      _sync.getEntryById(firestoreId);

  /// Same as [getEntryById] but accepts the int hash form
  /// (`WorkoutLogEntry.id`). Internally scans all entries to translate
  /// the int hash back to its firestoreId. Needed because the
  /// delete-from-tracking flow only has the int `WorkoutLogEntry.id`
  /// available, not the Firestore id.
  Future<WorkoutLogEntryModel?> getEntryByIdByHash(int entryId) async {
    final fid = await _resolveEntryById(entryId);
    if (fid == null) return null;
    return _sync.getEntryById(fid);
  }

  /// Same as [deleteEntry] but accepts the int hash form
  /// (`WorkoutLogEntry.id`) so the delete-from-tracking flow can fire
  /// without ever resolving the Firestore id.
  Future<int> deleteEntryByHash(int entryId) async {
    final fid = await _resolveEntryById(entryId);
    if (fid == null) return 0;
    return deleteEntry(fid);
  }

  Future<String?> _resolveEntryById(int entryId) async {
    final logs = await _sync.watchAllLogs().first;
    for (final log in logs) {
      if (log.firestoreId == null) continue;
      final entries = await _sync.getEntriesForLog(log.firestoreId!);
      for (final e in entries) {
        if (e.id == entryId) return e.firestoreId;
      }
    }
    return null;
  }

  Future<WorkoutLogModel?> findLogByFirestoreId(String fid) =>
      _sync.findLogByFirestoreId(fid);

  Future<WorkoutLogEntryModel?> findEntryByFirestoreId(String fid) =>
      _sync.findEntryByFirestoreId(fid);

  Stream<List<WorkoutLogEntryModel>> watchAllEntries() =>
      _sync.watchAllEntries();

  Stream<List<WorkoutLogEntryModel>> watchEntriesForLog(String logFid) =>
      _sync.watchEntriesForLog(logFid);

  /// Same as [watchEntriesForLog] but accepts the int hash form
  /// (`WorkoutLog.id`). Switches to the matching log's actual
  /// firestoreId on first emit.
  Stream<List<WorkoutLogEntryModel>> watchEntriesForLogById(int logId) async* {
    final resolved = await _resolveLogById(logId);
    if (resolved == null) {
      yield const <WorkoutLogEntryModel>[];
      return;
    }
    yield* _sync.watchEntriesForLog(resolved);
  }

  Future<String?> _resolveLogById(int logId) async {
    final logs = await _sync.watchAllLogs().first;
    for (final log in logs) {
      if (log.id == logId) return log.firestoreId;
    }
    return null;
  }

  /// Streams the single entry per workout for today's log, keyed by
  /// `workoutFirestoreId`. Falls back to the int `workoutId.hashCode`
  /// cast as a string when the Firestore id is missing (legacy rows
  /// that pre-date the migration). Callers that consume this map need
  /// to be aware of the mixed key space — the today page's data
  /// source translates it back to an int-keyed map using
  /// `entry.workoutId`.
  Stream<Map<String, WorkoutLogEntryModel>> watchEntriesByWorkoutForLog(
    String logFid,
  ) {
    return _sync.watchEntriesForLog(logFid).map((entries) {
      final map = <String, WorkoutLogEntryModel>{};
      for (final e in entries) {
        final wfid = e.workoutFirestoreId;
        if (wfid != null && wfid.isNotEmpty) {
          map[wfid] = e;
        } else if (e.workoutId != 0) {
          // Legacy rows: synthesise a stable string key from the int
          // hash so the entry still surfaces in the join. The today
          // page's repository translates this back to an int.
          map['__legacy_${e.workoutId}'] = e;
        }
      }
      return map;
    });
  }

  /// Returns the most recent prior entry per workout id (excluding
  /// entries that belong to today's log). Result is keyed by
  /// `workoutFirestoreId`.
  Future<Map<String, WorkoutLogEntryModel>> getLastEntriesForWorkouts(
    List<String> workoutFirestoreIds, {
    required DateTime beforeDay,
  }) => _sync.getLastEntriesForWorkouts(
    workoutFirestoreIds,
    beforeDay: beforeDay,
  );
}

/// `DayEntryRow` is defined on [SyncService] (re-imported above). It
/// describes a joined (entry, logFid) pair returned by
/// [WorkoutLogDao.watchEntriesForDay] for grouping entries by log in
/// the history read path.

// ---------------------------------------------------------------------------
// copyWith helpers used by the DAO for insert/update flows. They live
// here (rather than on the model) so the model stays a pure data
// carrier without any DAO coupling.
// ---------------------------------------------------------------------------

extension on WorkoutLogModel {
  WorkoutLogModel copyWith({String? firestoreId}) {
    return WorkoutLogModel(
      id: id,
      sessionId: sessionId,
      performedAt: performedAt,
      firestoreId: firestoreId ?? this.firestoreId,
      sessionFirestoreId: sessionFirestoreId,
      updatedAt: updatedAt,
    );
  }
}
