import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/history/data/models/freeze_day_model.dart';
import '../../features/profile/data/profile_json.dart';
import '../../features/profile/data/profile_service.dart';
import '../../features/session/data/models/session_model.dart';
import '../../features/workout/data/models/workout_model.dart';
import '../../features/workout_log/data/models/workout_log_entry_model.dart';
import '../../features/workout_log/data/models/workout_log_model.dart';
import 'firestore_id.dart';
import 'firestore_paths.dart';
import 'sync_snapshot.dart';
import 'sync_status.dart';
import 'uid_provider.dart';

/// The single seam between the app and Cloud Firestore.
///
/// Firestore is the **only source of truth** — there is no local SQLite
/// mirror. Every write hits Firestore directly. Every read subscribes to a
/// Firestore collection snapshot and emits parsed models.
///
/// Design rules:
/// 1. **Reads are push-based.** `watch*` methods return the Firestore SDK
///    stream mapped to a `List<*Model>`. The widget/repo subscribes once
///    and receives a fresh value on every remote change.
/// 2. **Writes are best-effort.** `upload*` calls fire-and-forget;
///    failures flip [SyncStatusController] to `failed` and the next
///    successful sync overwrites the row with the latest state.
/// 3. **No throw.** Every public method catches its own errors and
///    surfaces them via [_status] rather than the call stack.
class SyncService {
  SyncService({
    FirebaseFirestore? firestore,
    SyncStatusController? statusController,
  }) : _fs = firestore ?? FirebaseFirestore.instance,
       _status = statusController;

  final FirebaseFirestore _fs;
  final SyncStatusController? _status;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _userSub(String uid, String sub) =>
      _fs.collection(FirestorePaths.users).doc(uid).collection(sub);

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  Future<void> uploadProfile(UserProfile profile) async {
    final uid = currentFirestoreUid();
    if (uid == null) return;
    _status?.set(SyncStatus.syncing);
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.profile)
          .doc('profile')
          .set(ProfileJson.toMap(profile));
      _status?.set(SyncStatus.synced);
    } catch (e) {
      _onError('uploadProfile', e);
    }
  }

  Future<void> deleteProfile() async {
    final uid = currentFirestoreUid();
    if (uid == null) return;
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.profile)
          .doc('profile')
          .delete();
    } catch (e) {
      _onError('deleteProfile', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  Future<void> uploadSettings({
    required String unit,
    required bool notifications,
    required bool weeklyReports,
    required int reminderHour,
    required int reminderMinute,
  }) async {
    final uid = currentFirestoreUid();
    if (uid == null) return;
    _status?.set(SyncStatus.syncing);
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.settings)
          .doc('settings')
          .set(
            SettingsSnapshot(
              unit: unit,
              notifications: notifications,
              weeklyReports: weeklyReports,
              reminderHour: reminderHour,
              reminderMinute: reminderMinute,
            ).toJson(),
          );
      _status?.set(SyncStatus.synced);
    } catch (e) {
      _onError('uploadSettings', e);
    }
  }

  Future<void> deleteSettings() async {
    final uid = currentFirestoreUid();
    if (uid == null) return;
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.settings)
          .doc('settings')
          .delete();
    } catch (e) {
      _onError('deleteSettings', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Sessions
  // ---------------------------------------------------------------------------

  Future<void> uploadSession(SessionModel session) async {
    final uid = currentFirestoreUid();
    final fid = session.firestoreId;
    if (uid == null || fid == null) return;
    _status?.set(SyncStatus.syncing);
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.sessions)
          .doc(fid)
          .set(session.toJson());
      _status?.set(SyncStatus.synced);
    } catch (e) {
      _onError('uploadSession', e);
    }
  }

  Future<void> deleteSession(String firestoreId) async {
    final uid = currentFirestoreUid();
    if (uid == null) return;
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.sessions)
          .doc(firestoreId)
          .delete();
    } catch (e) {
      _onError('deleteSession', e);
    }
  }

  /// Streams every session, ordered by `updatedAt desc` then `createdAt desc`.
  Stream<List<SessionModel>> watchSessions() {
    final uid = currentFirestoreUid();
    if (uid == null) return Stream.value(const <SessionModel>[]);
    final query = _userSub(
      uid,
      FirestorePaths.sessions,
    ).orderBy('updatedAt', descending: true);
    return query.snapshots().map(
      (snap) => <SessionModel>[
        for (final doc in snap.docs) SessionModel.fromJson(doc.data()),
      ],
    );
  }

  Future<List<SessionModel>> getSessionsByIds(List<String> fids) async {
    final uid = currentFirestoreUid();
    if (uid == null || fids.isEmpty) return const <SessionModel>[];
    final results = await Future.wait<Object>([
      for (final fid in fids)
        _userSub(uid, FirestorePaths.sessions).doc(fid).get(),
    ]);
    return <SessionModel>[
      for (final r in results)
        if (r is DocumentSnapshot && r.exists)
          SessionModel.fromJson(r.data() as Map<String, dynamic>),
    ];
  }

  Future<SessionModel?> getSessionById(String fid) async {
    final uid = currentFirestoreUid();
    if (uid == null) return null;
    final doc = await _userSub(uid, FirestorePaths.sessions).doc(fid).get();
    if (!doc.exists) return null;
    return SessionModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<SessionModel?> findSessionByFirestoreId(String fid) =>
      getSessionById(fid);

  // ---------------------------------------------------------------------------
  // Workouts (master + join rows)
  // ---------------------------------------------------------------------------

  Future<void> uploadMasterWorkout(WorkoutModel model) async {
    final uid = currentFirestoreUid();
    final masterFid = model.masterFirestoreId;
    if (uid == null || masterFid == null) return;
    _status?.set(SyncStatus.syncing);
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.workouts)
          .doc(masterFid)
          .set({
            'firestoreId': masterFid,
            'exerciseName': model.exerciseName,
            'targetedBodyPart': model.targetedBodyPart?.id,
            'createdAt':
                (model.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
            'updatedAt': model.updatedAt?.millisecondsSinceEpoch,
          });
      _status?.set(SyncStatus.synced);
    } catch (e) {
      _onError('uploadMasterWorkout', e);
    }
  }

  Future<void> uploadSessionWorkout(WorkoutModel model) async {
    final uid = currentFirestoreUid();
    final fid = model.firestoreId;
    if (uid == null || fid == null) return;
    _status?.set(SyncStatus.syncing);
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.sessionWorkouts)
          .doc(fid)
          .set(model.toJson());
      _status?.set(SyncStatus.synced);
    } catch (e) {
      _onError('uploadSessionWorkout', e);
    }
  }

  Future<void> deleteSessionWorkout(String firestoreId) async {
    final uid = currentFirestoreUid();
    if (uid == null) return;
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.sessionWorkouts)
          .doc(firestoreId)
          .delete();
    } catch (e) {
      _onError('deleteSessionWorkout', e);
    }
  }

  /// Streams every join-row workout, ordered by `position` ascending.
  Stream<List<WorkoutModel>> watchAllWorkouts() {
    final uid = currentFirestoreUid();
    if (uid == null) return Stream.value(const <WorkoutModel>[]);
    final query = _userSub(
      uid,
      FirestorePaths.sessionWorkouts,
    ).orderBy('position', descending: false);
    return query.snapshots().map(
      (snap) => <WorkoutModel>[
        for (final doc in snap.docs) WorkoutModel.fromJson(doc.data()),
      ],
    );
  }

  /// Streams every join-row that belongs to a single session, sorted
  /// by `position` client-side (Firestore `where` + `orderBy` on
  /// different fields needs a composite index we don't ship).
  Stream<List<WorkoutModel>> watchBySession(String sessionFid) {
    final uid = currentFirestoreUid();
    if (uid == null) return Stream.value(const <WorkoutModel>[]);
    final query = _userSub(
      uid,
      FirestorePaths.sessionWorkouts,
    ).where('sessionFirestoreId', isEqualTo: sessionFid);
    return query.snapshots().map((snap) {
      final rows = <WorkoutModel>[
        for (final doc in snap.docs) WorkoutModel.fromJson(doc.data()),
      ];
      rows.sort((a, b) => a.position.compareTo(b.position));
      return rows;
    });
  }

  Future<List<WorkoutModel>> getByIds(List<String> fids) async {
    final uid = currentFirestoreUid();
    if (uid == null || fids.isEmpty) return const <WorkoutModel>[];
    final results = await Future.wait<Object>([
      for (final fid in fids)
        _userSub(uid, FirestorePaths.sessionWorkouts).doc(fid).get(),
    ]);
    return <WorkoutModel>[
      for (final r in results)
        if (r is DocumentSnapshot && r.exists)
          WorkoutModel.fromJson(r.data() as Map<String, dynamic>),
    ];
  }

  /// Look up join-row workouts by their master workout Firestore id.
  /// Used by the history feature, which receives master ids from
  /// `WorkoutLogEntry.workoutFirestoreId` (masterFirestoreId) and
  /// needs to resolve them back to the join row that carries
  /// `exerciseName` for display in the calendar's daily details.
  /// `getByIds` (above) does a doc-id lookup, which only works for
  /// the join row's own `firestoreId` — not for `masterFirestoreId`,
  /// so we expose a field-based query here.
  Future<List<WorkoutModel>> getByMasterIds(List<String> masterFids) async {
    final uid = currentFirestoreUid();
    if (uid == null || masterFids.isEmpty) return const <WorkoutModel>[];
    final out = <WorkoutModel>[];
    for (final batch in _chunked(masterFids, 30)) {
      final query = _userSub(
        uid,
        FirestorePaths.sessionWorkouts,
      ).where('masterFirestoreId', whereIn: batch);
      final snap = await query.get();
      for (final doc in snap.docs) {
        out.add(WorkoutModel.fromJson(doc.data()));
      }
    }
    return out;
  }

  Future<WorkoutModel?> getById(String fid) async {
    final uid = currentFirestoreUid();
    if (uid == null) return null;
    final doc = await _userSub(
      uid,
      FirestorePaths.sessionWorkouts,
    ).doc(fid).get();
    if (!doc.exists) return null;
    return WorkoutModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<WorkoutModel?> findByFirestoreId(String fid) => getById(fid);

  // ---------------------------------------------------------------------------
  // Workout logs
  // ---------------------------------------------------------------------------

  Future<void> uploadWorkoutLog(WorkoutLogModel model) async {
    final uid = currentFirestoreUid();
    final fid = model.firestoreId;
    if (uid == null || fid == null) return;
    _status?.set(SyncStatus.syncing);
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.workoutLogs)
          .doc(fid)
          .set(model.toJson());
      _status?.set(SyncStatus.synced);
    } catch (e) {
      _onError('uploadWorkoutLog', e);
    }
  }

  Future<void> deleteWorkoutLog(String firestoreId) async {
    final uid = currentFirestoreUid();
    if (uid == null) return;
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.workoutLogs)
          .doc(firestoreId)
          .delete();
    } catch (e) {
      _onError('deleteWorkoutLog', e);
    }
  }

  /// Streams every workout log, sorted by `performedAt` descending
  /// client-side (Firestore returns results unordered so we don't need
  /// a composite index).
  Stream<List<WorkoutLogModel>> watchAllLogs() {
    final uid = currentFirestoreUid();
    if (uid == null) return Stream.value(const <WorkoutLogModel>[]);
    final query = _userSub(uid, FirestorePaths.workoutLogs);
    return query.snapshots().map((snap) {
      final logs = <WorkoutLogModel>[
        for (final doc in snap.docs) WorkoutLogModel.fromJson(doc.data()),
      ];
      logs.sort((a, b) => b.performedAt.compareTo(a.performedAt));
      return logs;
    });
  }

  Stream<List<WorkoutLogModel>> watchLogsInRange({
    required DateTime start,
    required DateTime end,
  }) {
    final uid = currentFirestoreUid();
    if (uid == null) return Stream.value(const <WorkoutLogModel>[]);
    final query = _userSub(uid, FirestorePaths.workoutLogs)
        .where(
          'performedAt',
          isGreaterThanOrEqualTo: start.millisecondsSinceEpoch,
        )
        .where('performedAt', isLessThan: end.millisecondsSinceEpoch);
    return query.snapshots().map((snap) {
      final logs = <WorkoutLogModel>[
        for (final doc in snap.docs) WorkoutLogModel.fromJson(doc.data()),
      ];
      logs.sort((a, b) => b.performedAt.compareTo(a.performedAt));
      return logs;
    });
  }

  Stream<List<WorkoutLogModel>> watchLogsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return watchLogsInRange(start: start, end: end);
  }

  Future<WorkoutLogModel?> findLogForDay({
    required String sessionFid,
    required DateTime day,
  }) async {
    final uid = currentFirestoreUid();
    if (uid == null) return null;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    // Equality + range needs a composite index we don't want to ship,
    // so we filter the date range client-side after the indexed
    // session lookup.
    final query = _userSub(
      uid,
      FirestorePaths.workoutLogs,
    ).where('sessionFirestoreId', isEqualTo: sessionFid);
    final snap = await query.get();
    final candidates = <WorkoutLogModel>[
      for (final doc in snap.docs) WorkoutLogModel.fromJson(doc.data()),
    ];
    final inRange = candidates.where((l) {
      return !l.performedAt.isBefore(start) && l.performedAt.isBefore(end);
    }).toList();
    if (inRange.isEmpty) return null;
    inRange.sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return inRange.first;
  }

  Future<WorkoutLogModel?> getLogById(String fid) async {
    final uid = currentFirestoreUid();
    if (uid == null) return null;
    final doc = await _userSub(uid, FirestorePaths.workoutLogs).doc(fid).get();
    if (!doc.exists) return null;
    return WorkoutLogModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<WorkoutLogModel?> findLogByFirestoreId(String fid) => getLogById(fid);

  // ---------------------------------------------------------------------------
  // Workout log entries
  // ---------------------------------------------------------------------------

  Future<void> uploadWorkoutLogEntry(WorkoutLogEntryModel model) async {
    final uid = currentFirestoreUid();
    final fid = model.firestoreId;
    if (uid == null || fid == null) return;
    _status?.set(SyncStatus.syncing);
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.workoutLogEntries)
          .doc(fid)
          .set(model.toJson());
      _status?.set(SyncStatus.synced);
    } catch (e) {
      _onError('uploadWorkoutLogEntry', e);
    }
  }

  Future<void> deleteWorkoutLogEntry(String firestoreId) async {
    final uid = currentFirestoreUid();
    if (uid == null) return;
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.workoutLogEntries)
          .doc(firestoreId)
          .delete();
    } catch (e) {
      _onError('deleteWorkoutLogEntry', e);
    }
  }

  /// Streams every entry for a single log, sorted by `position` then
  /// `setIndex` client-side (composite `where` + multi-`orderBy` would
  /// need an index we don't ship).
  Stream<List<WorkoutLogEntryModel>> watchEntriesForLog(String logFid) {
    final uid = currentFirestoreUid();
    if (uid == null) return Stream.value(const <WorkoutLogEntryModel>[]);
    final query = _userSub(
      uid,
      FirestorePaths.workoutLogEntries,
    ).where('workoutLogFirestoreId', isEqualTo: logFid);
    return query.snapshots().map((snap) {
      final entries = <WorkoutLogEntryModel>[
        for (final doc in snap.docs) WorkoutLogEntryModel.fromJson(doc.data()),
      ];
      entries.sort((a, b) {
        final byPos = a.position.compareTo(b.position);
        if (byPos != 0) return byPos;
        return a.setIndex.compareTo(b.setIndex);
      });
      return entries;
    });
  }

  /// Streams every entry grouped by parent log. The returned list is
  /// shaped as `(entry, logFid)` pairs so the UI can stack entries per
  /// log id without a second round-trip.
  Stream<List<DayEntryRow>> watchEntriesForDay(DateTime day) {
    final uid = currentFirestoreUid();
    if (uid == null) return Stream.value(const <DayEntryRow>[]);

    // 1. Get logs for the day.
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final logsQuery = _userSub(uid, FirestorePaths.workoutLogs)
        .where(
          'performedAt',
          isGreaterThanOrEqualTo: start.millisecondsSinceEpoch,
        )
        .where('performedAt', isLessThan: end.millisecondsSinceEpoch);

    // 2. Watch all entries for the user.
    final entriesStream = watchAllEntries();

    // 3. Combine them to filter entries by the logs on this specific day.
    // This ensures real-time updates for entry edits (e.g. rep changes)
    // without complex per-log listeners.
    return logsQuery.snapshots().asyncExpand((logsSnap) {
      final logFids = logsSnap.docs.map((doc) => doc.id).toSet();

      return entriesStream.map((allEntries) {
        final rows = <DayEntryRow>[];
        for (final entry in allEntries) {
          if (logFids.contains(entry.workoutLogFirestoreId)) {
            rows.add(
              DayEntryRow(entry: entry, logFid: entry.workoutLogFirestoreId!),
            );
          }
        }
        // Grouping is handled by HistoryLocalDataSource; sorting matches
        // the existing watchEntriesForLog contract.
        rows.sort((a, b) {
          final byPos = a.entry.position.compareTo(b.entry.position);
          if (byPos != 0) return byPos;
          return a.entry.setIndex.compareTo(b.entry.setIndex);
        });
        return rows;
      });
    });
  }

  Future<List<WorkoutLogEntryModel>> getEntriesForLog(String logFid) async {
    final uid = currentFirestoreUid();
    if (uid == null) return const <WorkoutLogEntryModel>[];
    final query = _userSub(
      uid,
      FirestorePaths.workoutLogEntries,
    ).where('workoutLogFirestoreId', isEqualTo: logFid);
    final snap = await query.get();
    final entries = <WorkoutLogEntryModel>[
      for (final doc in snap.docs) WorkoutLogEntryModel.fromJson(doc.data()),
    ];
    entries.sort((a, b) {
      final byPos = a.position.compareTo(b.position);
      if (byPos != 0) return byPos;
      return a.setIndex.compareTo(b.setIndex);
    });
    return entries;
  }

  Future<WorkoutLogEntryModel?> getEntryById(String fid) async {
    final uid = currentFirestoreUid();
    if (uid == null) return null;
    final doc = await _userSub(
      uid,
      FirestorePaths.workoutLogEntries,
    ).doc(fid).get();
    if (!doc.exists) return null;
    return WorkoutLogEntryModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<WorkoutLogEntryModel?> findEntryByFirestoreId(String fid) =>
      getEntryById(fid);

  /// Streams every workout log entry for the current user.
  Stream<List<WorkoutLogEntryModel>> watchAllEntries() {
    final uid = currentFirestoreUid();
    if (uid == null) return Stream.value(const <WorkoutLogEntryModel>[]);
    final query = _userSub(uid, FirestorePaths.workoutLogEntries);
    return query.snapshots().map((snap) {
      return <WorkoutLogEntryModel>[
        for (final doc in snap.docs) WorkoutLogEntryModel.fromJson(doc.data()),
      ];
    });
  }

  /// Returns the most recent prior entry per workout id (excluding
  /// entries performed on or after [beforeDay]). Used by the prefill
  /// flow. Result is keyed by `workoutFirestoreId`.
  Future<Map<String, WorkoutLogEntryModel>> getLastEntriesForWorkouts(
    List<String> workoutFids, {
    required DateTime beforeDay,
  }) async {
    final uid = currentFirestoreUid();
    if (uid == null || workoutFids.isEmpty) return const {};
    // We can't filter `performedAt < cutoff` server-side without a
    // composite index we don't ship. Instead, fetch every entry for
    // the workouts in the batch and pick the latest createdAt
    // client-side. Entries carry `createdAt` (set on upload), which
    // is monotonic per entry — a good enough proxy for "most recent
    // prior log".
    final out = <String, WorkoutLogEntryModel>{};
    for (final batch in _chunked(workoutFids, 30)) {
      final query = _userSub(
        uid,
        FirestorePaths.workoutLogEntries,
      ).where('workoutFirestoreId', whereIn: batch);
      final snap = await query.get();
      for (final doc in snap.docs) {
        final entry = WorkoutLogEntryModel.fromJson(doc.data());
        final wfid = entry.workoutFirestoreId;
        if (wfid == null) continue;
        if (entry.createdAt == null) continue;
        // Skip entries added today or later — we want prior history.
        if (!entry.createdAt!.isBefore(beforeDay)) continue;
        final existing = out[wfid];
        if (existing == null ||
            (existing.createdAt != null &&
                entry.createdAt!.isAfter(existing.createdAt!))) {
          out[wfid] = entry;
        }
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Freezes
  // ---------------------------------------------------------------------------

  Future<void> uploadFreeze(FreezeDayModel freeze) async {
    final uid = currentFirestoreUid();
    final fid = freeze.firestoreId;
    if (uid == null || fid.isEmpty) return;
    _status?.set(SyncStatus.syncing);
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.freezes)
          .doc(fid)
          .set(freeze.toJson());
      _status?.set(SyncStatus.synced);
    } catch (e) {
      _onError('uploadFreeze', e);
    }
  }

  Future<void> deleteFreeze(String firestoreId) async {
    final uid = currentFirestoreUid();
    if (uid == null) return;
    try {
      await _fs
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.freezes)
          .doc(firestoreId)
          .delete();
    } catch (e) {
      _onError('deleteFreeze', e);
    }
  }

  Stream<Set<DateTime>> watchFrozenDays() {
    final uid = currentFirestoreUid();
    if (uid == null) return Stream.value(const <DateTime>{});
    final query = _userSub(uid, FirestorePaths.freezes).orderBy('day');
    return query.snapshots().map((snap) {
      return <DateTime>{
        for (final doc in snap.docs)
          if (doc.data()['day'] is int)
            DateTime.fromMillisecondsSinceEpoch(doc.data()['day'] as int),
      };
    });
  }

  Stream<List<FreezeDayModel>> watchFreezesInRange({
    required DateTime start,
    required DateTime end,
  }) {
    final uid = currentFirestoreUid();
    if (uid == null) return Stream.value(const <FreezeDayModel>[]);
    final query = _userSub(uid, FirestorePaths.freezes)
        .where('day', isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
        .where('day', isLessThan: end.millisecondsSinceEpoch)
        .orderBy('day', descending: true);
    return query.snapshots().map(
      (snap) => <FreezeDayModel>[
        for (final doc in snap.docs) FreezeDayModel.fromJson(doc.data()),
      ],
    );
  }

  Future<List<FreezeDayModel>> selectFreezesForDay(DateTime day) async {
    final uid = currentFirestoreUid();
    if (uid == null) return const <FreezeDayModel>[];
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final query = _userSub(uid, FirestorePaths.freezes)
        .where('day', isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
        .where('day', isLessThan: end.millisecondsSinceEpoch);
    final snap = await query.get();
    return <FreezeDayModel>[
      for (final doc in snap.docs) FreezeDayModel.fromJson(doc.data()),
    ];
  }

  /// Inserts a freeze row keyed by a fresh UUID and returns the new
  /// firestoreId so the caller can mirror the deletion if the user
  /// unfreezes the same day.
  Future<String> insertFreeze({required DateTime day, String note = ''}) async {
    final uid = currentFirestoreUid();
    if (uid == null) return '';
    final fid = newFirestoreId();
    final model = FreezeDayModel(
      firestoreId: fid,
      day: DateTime(day.year, day.month, day.day),
      note: note,
      updatedAt: DateTime.now(),
    );
    await uploadFreeze(model);
    return fid;
  }

  Future<void> deleteFreezeForDay(DateTime day) async {
    final rows = await selectFreezesForDay(day);
    for (final row in rows) {
      if (row.firestoreId.isNotEmpty) {
        await deleteFreeze(row.firestoreId);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Bulk download (kept for `downloadAll` callers — mostly unused now)
  // ---------------------------------------------------------------------------

  /// Downloads every subcollection + the profile + settings docs for
  /// the current user and returns a parsed [SyncSnapshot]. Returns an
  /// empty snapshot on error (caller can decide to log + continue).
  ///
  /// No longer used by the auth restore path (no Drift to merge into),
  /// but kept for any future batch-import use case.
  Future<SyncSnapshot> downloadAll() async {
    final uid = currentFirestoreUid();
    if (uid == null) {
      return const SyncSnapshot(
        profile: null,
        settings: null,
        sessions: [],
        workouts: [],
        sessionWorkouts: [],
        workoutLogs: [],
        workoutLogEntries: [],
        freezes: [],
      );
    }

    _status?.set(SyncStatus.syncing);
    try {
      final userRoot = _fs.collection(FirestorePaths.users).doc(uid);

      final results = await Future.wait<Object>([
        userRoot.collection(FirestorePaths.profile).doc('profile').get(),
        userRoot.collection(FirestorePaths.settings).doc('settings').get(),
        userRoot.collection(FirestorePaths.sessions).get(),
        userRoot.collection(FirestorePaths.workouts).get(),
        userRoot.collection(FirestorePaths.sessionWorkouts).get(),
        userRoot.collection(FirestorePaths.workoutLogs).get(),
        userRoot.collection(FirestorePaths.workoutLogEntries).get(),
        userRoot.collection(FirestorePaths.freezes).get(),
      ]);

      final profileSnap = results[0] as DocumentSnapshot;
      final settingsSnap = results[1] as DocumentSnapshot;
      final sessionsSnap = results[2] as QuerySnapshot;
      final sessionWorkoutsSnap = results[4] as QuerySnapshot;
      final workoutLogsSnap = results[5] as QuerySnapshot;
      final workoutLogEntriesSnap = results[6] as QuerySnapshot;
      final freezesSnap = results[7] as QuerySnapshot;

      return SyncSnapshot(
        profile: profileSnap.exists
            ? ProfileJson.fromMap(profileSnap.data() as Map<String, dynamic>)
            : null,
        settings: settingsSnap.exists
            ? SettingsSnapshot.fromJson(
                settingsSnap.data() as Map<String, dynamic>,
              )
            : null,
        sessions: <SessionModel>[
          for (final doc in sessionsSnap.docs)
            SessionModel.fromJson(doc.data() as Map<String, dynamic>),
        ],
        workouts: const <WorkoutModel>[],
        sessionWorkouts: <WorkoutModel>[
          for (final doc in sessionWorkoutsSnap.docs)
            WorkoutModel.fromJson(doc.data() as Map<String, dynamic>),
        ],
        workoutLogs: <WorkoutLogModel>[
          for (final doc in workoutLogsSnap.docs)
            WorkoutLogModel.fromJson(doc.data() as Map<String, dynamic>),
        ],
        workoutLogEntries: <WorkoutLogEntryModel>[
          for (final doc in workoutLogEntriesSnap.docs)
            WorkoutLogEntryModel.fromJson(doc.data() as Map<String, dynamic>),
        ],
        freezes: <FreezeDayModel>[
          for (final doc in freezesSnap.docs)
            FreezeDayModel.fromJson(doc.data() as Map<String, dynamic>),
        ],
      );
    } catch (e) {
      _onError('downloadAll', e);
      return const SyncSnapshot(
        profile: null,
        settings: null,
        sessions: [],
        workouts: [],
        sessionWorkouts: [],
        workoutLogs: [],
        workoutLogEntries: [],
        freezes: [],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------

  void _onError(String op, Object error) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('SyncService.$op failed: $error');
    }
    _status?.set(SyncStatus.failed, message: op);
  }

  Iterable<List<T>> _chunked<T>(List<T> source, int size) sync* {
    for (var i = 0; i < source.length; i += size) {
      yield source.sublist(i, (i + size).clamp(0, source.length));
    }
  }
}

/// Joined (entry, logFid) pair emitted by [SyncService.watchEntriesForDay].
class DayEntryRow {
  const DayEntryRow({required this.entry, required this.logFid});

  final WorkoutLogEntryModel entry;
  final String logFid;
}
