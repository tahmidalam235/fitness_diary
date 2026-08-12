import '../../sync/firestore_id.dart';
import '../../sync/sync_service.dart';
import '../../../features/workout/data/models/workout_model.dart';

/// Firestore-backed replacement for the old Drift `SessionWorkoutDao`.
///
/// Identical public surface to the old DAO so the local data sources
/// can swap their DAO dependency for a `SyncService` field without
/// changing the rest of the call shape.
class SessionWorkoutDao {
  SessionWorkoutDao(this._sync);

  final SyncService _sync;

  /// Looks up the join rows attached to the session whose Firestore id
  /// is [sessionFirestoreId]. Returns a one-shot list (the source
  /// `Stream<List<WorkoutModel>>` in the old DAO became a `Stream` of
  /// `List` — we expose a `Future` here for the few callers that need
  /// a one-shot read; the streaming case uses `watchBySession` below).
  Future<List<WorkoutModel>> getBySession(String sessionFirestoreId) async {
    return _sync.watchBySession(sessionFirestoreId).first;
  }

  Stream<List<WorkoutModel>> watchBySession(String sessionFirestoreId) =>
      _sync.watchBySession(sessionFirestoreId);

  Future<int> insertSessionWorkout(WorkoutModel model) async {
    final fid = model.firestoreId ?? newFirestoreId();
    await _sync.uploadSessionWorkout(model.copyWith(firestoreId: fid));
    if (model.masterFirestoreId != null) {
      await _sync.uploadMasterWorkout(model);
    }
    return 1;
  }

  Future<bool> updateSessionWorkout(WorkoutModel model) async {
    await _sync.uploadSessionWorkout(model);
    if (model.masterFirestoreId != null) {
      await _sync.uploadMasterWorkout(model);
    }
    return true;
  }

  Future<WorkoutModel?> getById(String firestoreId) =>
      _sync.getById(firestoreId);

  Future<WorkoutModel?> findByFirestoreId(String fid) => _sync.findByFirestoreId(fid);

  Future<int> deleteById(String firestoreId) async {
    await _sync.deleteSessionWorkout(firestoreId);
    return 1;
  }

  Future<int> deleteBySession(String sessionFirestoreId) async {
    final rows = await getBySession(sessionFirestoreId);
    for (final row in rows) {
      if (row.firestoreId != null) {
        await _sync.deleteSessionWorkout(row.firestoreId!);
      }
    }
    return rows.length;
  }

  /// Returns the next available position for a session's workouts.
  Future<int> nextPosition(String sessionFirestoreId) async {
    final rows = await getBySession(sessionFirestoreId);
    if (rows.isEmpty) return 0;
    return rows.map((w) => w.position).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Persists a new ordering for the session from [orderedIds].
  Future<void> reorderSession({
    required String sessionFirestoreId,
    required List<String> orderedIds,
  }) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final existing = await getById(orderedIds[i]);
      if (existing == null) continue;
      final updated = existing.copyWith(position: i);
      await _sync.uploadSessionWorkout(updated);
    }
  }
}

extension on WorkoutModel {
  WorkoutModel copyWith({
    int? position,
    String? firestoreId,
  }) {
    return WorkoutModel(
      id: id,
      sessionId: sessionId,
      workoutId: workoutId,
      exerciseName: exerciseName,
      position: position ?? this.position,
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      defaultDurationSeconds: defaultDurationSeconds,
      defaultWeight: defaultWeight,
      notes: notes,
      firestoreId: firestoreId ?? this.firestoreId,
      masterFirestoreId: masterFirestoreId,
      sessionFirestoreId: sessionFirestoreId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}