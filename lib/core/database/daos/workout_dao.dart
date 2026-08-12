import '../../sync/firestore_id.dart';
import '../../sync/sync_service.dart';
import '../../../features/workout/data/models/workout_model.dart';

/// Firestore-backed replacement for the old Drift `WorkoutDao`.
///
/// Returns [WorkoutModel]s parsed from the `sessionWorkouts`
/// subcollection — master-only queries (which the old DAO also did)
/// are no longer needed because masters are uploaded inline with their
/// join rows.
class WorkoutDao {
  WorkoutDao(this._sync);

  final SyncService _sync;

  Future<List<WorkoutModel>> getAllWorkouts() async {
    return _sync.watchAllWorkouts().first;
  }

  Stream<List<WorkoutModel>> watchAllWorkouts() => _sync.watchAllWorkouts();

  Future<WorkoutModel?> getById(String firestoreId) =>
      _sync.getById(firestoreId);

  Future<List<WorkoutModel>> getByIds(List<String> fids) =>
      _sync.getByIds(fids);

  /// Look up join-row workouts by master Firestore id. Mirrors
  /// [getByIds] but queries the `masterFirestoreId` field instead of
  /// the document id — needed when callers only have the master id
  /// (e.g. history feature resolving `WorkoutLogEntry.workoutFirestoreId`
  /// back to a join row carrying `exerciseName`).
  Future<List<WorkoutModel>> getByMasterIds(List<String> masterFids) =>
      _sync.getByMasterIds(masterFids);

  Future<WorkoutModel?> findByFirestoreId(String fid) =>
      _sync.findByFirestoreId(fid);

  /// Inserts (uploads) the master workout document only. Used by the
  /// insert flow after the caller has already uploaded the join row.
  Future<int> insertWorkout(WorkoutModel model) async {
    final fid = model.masterFirestoreId ?? newFirestoreId();
    await _sync.uploadMasterWorkout(model.copyWith(masterFirestoreId: fid));
    return 1;
  }

  Future<bool> updateWorkout(WorkoutModel model) async {
    await _sync.uploadMasterWorkout(model);
    return true;
  }

  Future<int> deleteWorkout(String masterFirestoreId) async {
    // In the Firestore-only world the master doc is informational only;
    // there is no "master without joins" invariant to enforce. We leave
    // the master doc alone so historical joins still resolve.
    // If we wanted a strict delete, we'd remove the master doc here.
    // For now this is a no-op so existing master docs aren't orphaned.
    if (masterFirestoreId.isEmpty) return 0;
    return 0;
  }
}

extension on WorkoutModel {
  WorkoutModel copyWith({String? masterFirestoreId}) {
    return WorkoutModel(
      id: id,
      sessionId: sessionId,
      workoutId: workoutId,
      exerciseName: exerciseName,
      position: position,
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      defaultDurationSeconds: defaultDurationSeconds,
      defaultWeight: defaultWeight,
      notes: notes,
      targetedBodyPart: targetedBodyPart,
      firestoreId: firestoreId,
      masterFirestoreId: masterFirestoreId ?? this.masterFirestoreId,
      sessionFirestoreId: sessionFirestoreId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}