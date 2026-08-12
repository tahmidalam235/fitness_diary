import '../../../../core/database/daos/session_dao.dart';
import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/firestore_id.dart';
import '../../../workout/data/datasources/workout_local_datasource.dart';
import '../models/workout_log_entry_model.dart';
import '../models/workout_log_model.dart';

/// Firestore-backed adapter for the daily workout log feature.
///
/// Method signatures match the original Drift-backed data source. The
/// repository layer doesn't change.
class WorkoutLogLocalDataSource {
  const WorkoutLogLocalDataSource({
    required this.workoutLogDao,
    required this.workoutLocalDataSource,
    this.sessionDao,
  });

  final WorkoutLogDao workoutLogDao;
  final WorkoutLocalDataSource workoutLocalDataSource;
  final SessionDao? sessionDao;

  Future<WorkoutLogModel> getOrCreateTodayLog(String sessionFirestoreId) async {
    try {
      final today = DateTime.now();
      final existing = await workoutLogDao.findLogForDay(
        sessionFirestoreId: sessionFirestoreId,
        day: today,
      );
      if (existing != null) {
        return _hydrateLog(existing);
      }
      final fid = newFirestoreId();
      final now = DateTime(today.year, today.month, today.day);
      final model = WorkoutLogModel(
        id: fid.hashCode,
        sessionId: sessionFirestoreId.hashCode,
        performedAt: now,
        firestoreId: fid,
        sessionFirestoreId: sessionFirestoreId,
        updatedAt: DateTime.now(),
      );
      await workoutLogDao.insertLog(model);
      final fresh = await workoutLogDao.getLogById(fid);
      return _hydrateLog(fresh ?? model);
    } catch (error) {
      throw DatabaseException(
        'Failed to load today\'s workout log',
        cause: error,
      );
    }
  }

  /// Read-only lookup of today's log for [sessionFirestoreId].
  /// Returns `null` if no log row exists yet — unlike
  /// [getOrCreateTodayLog] this never inserts a placeholder row, so
  /// read-only consumers (e.g. the today-page picker) don't leave
  /// empty logs behind when the user backs out without picking.
  Future<WorkoutLogModel?> findTodayLog(String sessionFirestoreId) async {
    try {
      final model = await workoutLogDao.findLogForDay(
        sessionFirestoreId: sessionFirestoreId,
        day: DateTime.now(),
      );
      if (model == null) return null;
      return _hydrateLog(model);
    } catch (error) {
      throw DatabaseException(
        'Failed to find today\'s workout log',
        cause: error,
      );
    }
  }

  /// Streams today's entries for [sessionFirestoreId] as a
  /// `Map<workoutFirestoreId, entry>` so the UI can look up the single
  /// row per workout directly.
  Stream<Map<String, WorkoutLogEntryModel>> watchTodayEntriesByWorkout(
    String sessionFirestoreId,
  ) async* {
    try {
      final log = await workoutLogDao.findLogForDay(
        sessionFirestoreId: sessionFirestoreId,
        day: DateTime.now(),
      );
      if (log == null || log.firestoreId == null) {
        yield const <String, WorkoutLogEntryModel>{};
        return;
      }
      yield* workoutLogDao.watchEntriesByWorkoutForLog(log.firestoreId!).map((
        map,
      ) {
        return <String, WorkoutLogEntryModel>{
          for (final entry in map.values)
            // Keep both populated and "legacy" (no workoutFirestoreId)
            // entries in the stream. The DAO already synthesises a
            // stable key for legacy rows via `__legacy_${workoutId}`
            // — filtering them out here used to drop seed rows that
            // were inserted before the masterFirestoreId was stamped,
            // hiding the user's edit from the today page.
            if (entry.workoutFirestoreId != null)
              entry.workoutFirestoreId!: entry.copyWith(
                workoutLogFirestoreId: log.firestoreId,
              )
            else if (entry.workoutId != 0)
              '__legacy_${entry.workoutId}': entry.copyWith(
                workoutLogFirestoreId: log.firestoreId,
              ),
        };
      });
    } catch (error) {
      throw DatabaseException(
        'Failed to watch today\'s workout entries',
        cause: error,
      );
    }
  }

  /// Returns the [WorkoutLogEntryModel] for the Firestore id, including
  /// the [WorkoutLogEntryModel.workoutLogFirestoreId] stamp needed by
  /// the sync layer. Returns `null` if no row matches.
  Future<WorkoutLogEntryModel?> getEntryById(String fid) async {
    try {
      final row = await workoutLogDao.getEntryById(fid);
      if (row == null) return null;
      return row;
    } catch (error) {
      throw DatabaseException(
        'Failed to load workout log entry $fid',
        cause: error,
      );
    }
  }

  Future<WorkoutLogEntryModel> upsertEntry(WorkoutLogEntryModel model) async {
    try {
      final fid = model.firestoreId ?? newFirestoreId();
      final stored = model.copyWith(firestoreId: fid);
      await workoutLogDao.insertEntry(stored);
      final fresh = await workoutLogDao.getEntryById(fid);
      return fresh ?? stored;
    } catch (error) {
      throw DatabaseException(
        'Failed to upsert workout log entry',
        cause: error,
      );
    }
  }

  /// Deletes the entry identified by [fid] and returns the deleted
  /// entry's `firestoreId` so the cloud counterpart can be removed
  /// too.
  ///
  /// [fid] may be either a Firestore document id (string) or the int
  /// hash derived from it (`WorkoutLogEntry.id`). The int-hash form is
  /// the common path — the tracking page only has the int available.
  /// We resolve it to the actual Firestore id before issuing the
  /// delete so the today page's entries stream sees the removal and
  /// the card disappears.
  ///
  /// Returns the firestoreId of the deleted row, or `null` if no row
  /// matched.
  Future<String?> deleteEntry(String fid) async {
    try {
      String? actualFid = await resolveEntryFirestoreId(fid);
      if (actualFid == null || actualFid.isEmpty) return null;
      await workoutLogDao.deleteEntry(actualFid);
      return actualFid;
    } catch (error) {
      throw DatabaseException(
        'Failed to delete workout log entry',
        cause: error,
      );
    }
  }

  /// Returns the parent `workoutLogFirestoreId` for the entry whose
  /// Firestore doc id is [entryFid], or `null` if no such row exists.
  /// Used by the entry-delete path to look up the parent log so we can
  /// garbage-collect it when its last child entry is removed.
  Future<String?> entryWorkoutLogFirestoreId(String entryFid) async {
    try {
      final row = await workoutLogDao.getEntryById(entryFid);
      return row?.workoutLogFirestoreId;
    } catch (error) {
      throw DatabaseException(
        'Failed to load parent workout log for entry $entryFid',
        cause: error,
      );
    }
  }

  /// Returns every entry that belongs to the workout log whose
  /// Firestore doc id is [logFid]. Used by the entry-delete path to
  /// detect whether the parent log still has any surviving entries
  /// after a delete — if not, the parent log is garbage-collected so
  /// the session stops appearing on the Today page and the Calendar.
  Future<List<WorkoutLogEntryModel>> getEntriesForLog(String logFid) async {
    try {
      return await workoutLogDao.getEntriesForLog(logFid);
    } catch (error) {
      throw DatabaseException(
        'Failed to list workout log entries for log $logFid',
        cause: error,
      );
    }
  }

  /// Resolves an entry identifier to its Firestore document id.
  /// Accepts either a Firestore id (string) or the int hash form
  /// (`WorkoutLogEntry.id`).
  Future<String?> resolveEntryFirestoreId(String fid) async {
    // Try the int-hash form first — that's how callers from the
    // tracking page reach us. If [fid] isn't a valid int we fall back
    // to a direct Firestore document lookup.
    final intHash = int.tryParse(fid);
    if (intHash != null && intHash > 0) {
      final byHash = await workoutLogDao.getEntryByIdByHash(intHash);
      if (byHash != null && byHash.firestoreId != null) {
        return byHash.firestoreId;
      }
    }
    final direct = await workoutLogDao.getEntryById(fid);
    return direct?.firestoreId;
  }

  /// Adds the given entries to today's log for [sessionFirestoreId]
  /// (creating the log row lazily). One entry per selected workout.
  ///
  /// Idempotent for `(sessionFirestoreId, workoutFirestoreId)`: an
  /// input entry whose `workoutFirestoreId` already has an entry in
  /// today's log is skipped (no duplicate insert). Without this guard,
  /// the bloc's seed-from-prior path could overwrite a user's
  /// already-saved values when a stream-snapshot race returned an
  /// empty entry map for today's log — the seed row would be inserted
  /// and the entries-stream map (keyed by `workoutFirestoreId.hashCode`)
  /// would collapse both into one, leaving the user with default
  /// values rather than their saved values.
  ///
  /// Returns both the [WorkoutLogModel] and the freshly-inserted
  /// entry models so the repository can fire one upload per
  /// newly-written row. Skipped entries are not in the returned list —
  /// callers rely on the entries stream to surface pre-existing rows.
  Future<({WorkoutLogModel log, List<WorkoutLogEntryModel> entries})>
  addWorkoutsToToday({
    required String sessionFirestoreId,
    required List<WorkoutLogEntryModel> entries,
  }) async {
    try {
      final log = await getOrCreateTodayLog(sessionFirestoreId);
      // Snapshot the existing entries for this log up-front so the
      // dedupe check doesn't race with the inserts we're about to do.
      final existingByWorkoutFid = <String>{};
      final logFid = log.firestoreId;
      if (logFid != null && logFid.isNotEmpty) {
        final existing = await workoutLogDao.getEntriesForLog(logFid);
        for (final e in existing) {
          final wfid = e.workoutFirestoreId;
          if (wfid != null && wfid.isNotEmpty) {
            existingByWorkoutFid.add(wfid);
          }
        }
      }
      final inserted = <WorkoutLogEntryModel>[];
      for (final entry in entries) {
        final wfid = entry.workoutFirestoreId;
        // Skip if this workout already has a today's entry — its
        // values must be preserved.
        if (wfid != null &&
            wfid.isNotEmpty &&
            existingByWorkoutFid.contains(wfid)) {
          continue;
        }
        final fid = newFirestoreId();
        final stored = entry.copyWithFields(
          id: 0,
          workoutLogId: log.id,
          firestoreId: fid,
          workoutLogFirestoreId: log.firestoreId,
        );
        await workoutLogDao.insertEntry(stored);
        final fresh = await workoutLogDao.getEntryById(fid);
        if (fresh != null) inserted.add(fresh);
        if (wfid != null && wfid.isNotEmpty) {
          existingByWorkoutFid.add(wfid);
        }
      }
      return (log: log, entries: inserted);
    } catch (error) {
      throw DatabaseException(
        'Failed to add workouts to today\'s log',
        cause: error,
      );
    }
  }

  /// Returns the most recent prior entry per workout id (excluding
  /// today). Used to prefill the tracking card with yesterday's
  /// values. Result is keyed by `workoutFirestoreId`.
  Future<Map<String, WorkoutLogEntryModel>> getLastEntriesForWorkouts(
    List<String> workoutFirestoreIds,
  ) async {
    try {
      final today = DateTime.now();
      return await workoutLogDao.getLastEntriesForWorkouts(
        workoutFirestoreIds,
        beforeDay: today,
      );
    } catch (error) {
      throw DatabaseException(
        'Failed to load previous workout entries',
        cause: error,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------

  WorkoutLogModel _hydrateLog(WorkoutLogModel row) {
    // Parent session is resolved by Firestore id; nothing to fetch.
    return row;
  }
}

extension on WorkoutLogEntryModel {
  WorkoutLogEntryModel copyWith({
    int? id,
    int? workoutLogId,
    String? firestoreId,
    String? workoutLogFirestoreId,
    String? workoutFirestoreId,
  }) {
    return WorkoutLogEntryModel(
      id: id ?? this.id,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      workoutId: workoutId,
      setIndex: setIndex,
      position: position,
      sets: sets,
      reps: reps,
      weight: weight,
      durationSeconds: durationSeconds,
      restSeconds: restSeconds,
      notes: notes,
      firestoreId: firestoreId ?? this.firestoreId,
      workoutLogFirestoreId:
          workoutLogFirestoreId ?? this.workoutLogFirestoreId,
      workoutFirestoreId: workoutFirestoreId ?? this.workoutFirestoreId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  WorkoutLogEntryModel copyWithFields({
    int? id,
    int? workoutLogId,
    String? firestoreId,
    String? workoutLogFirestoreId,
    String? workoutFirestoreId,
  }) {
    return copyWith(
      id: id,
      workoutLogId: workoutLogId,
      firestoreId: firestoreId,
      workoutLogFirestoreId: workoutLogFirestoreId,
      workoutFirestoreId: workoutFirestoreId,
    );
  }
}
