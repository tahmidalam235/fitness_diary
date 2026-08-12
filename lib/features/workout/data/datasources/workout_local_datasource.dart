import '../../../../core/database/daos/session_dao.dart';
import '../../../../core/database/daos/session_workout_dao.dart';
import '../../../../core/database/daos/workout_dao.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/firestore_id.dart';
import '../models/workout_model.dart';

/// Firestore-backed adapter for the workout feature. Translates
/// high-level workout operations into `SessionWorkoutDao` /
/// `WorkoutDao` calls. The `database` / `AppDatabase` field is gone
/// — there is no local SQLite mirror.
class WorkoutLocalDataSource {
  const WorkoutLocalDataSource({
    required this.sessionWorkoutDao,
    required this.workoutDao,
    this.sessionDao,
  });

  final SessionWorkoutDao sessionWorkoutDao;
  final WorkoutDao workoutDao;
  final SessionDao? sessionDao;

  Stream<List<WorkoutModel>> watchForSession(String sessionId) {
    try {
      // sessionId can be either a Firestore document id (string UUID)
      // or the int hashCode derived from it (when callers receive the
      // session id from the [Session] entity). To support both, we
      // attempt the direct lookup first and fall back to scanning all
      // join rows for a matching int hash.
      return workoutDao.watchAllWorkouts().map((all) {
        final byDirect = all.where((w) => w.sessionFirestoreId == sessionId);
        if (byDirect.isNotEmpty) return byDirect.toList();
        final intHash = int.tryParse(sessionId);
        if (intHash == null) return const <WorkoutModel>[];
        return all.where((w) => w.sessionId == intHash).toList();
      });
    } catch (error) {
      throw DatabaseException(
        'Failed to watch workouts for session $sessionId',
        cause: error,
      );
    }
  }

  Future<WorkoutModel> insert({
    required String sessionId,
    required String exerciseName,
    required int defaultSets,
    required int defaultReps,
    int? defaultDurationSeconds,
    double? defaultWeight,
    required String notes,
  }) async {
    if (sessionId.isEmpty) {
      throw ValidationException(
        'Invalid session id',
        errors: {'sessionId': 'Invalid session id'},
      );
    }

    try {
      final now = DateTime.now();

      // Duplicate check — Firestore can't enforce per-session uniqueness
      // for a string field, so we do it client-side.
      final existingRows = await sessionWorkoutDao.getBySession(sessionId);
      final normalizedSearch = exerciseName.trim().toLowerCase();
      if (existingRows.any(
        (r) => r.exerciseName.trim().toLowerCase() == normalizedSearch,
      )) {
        throw const ValidationException(
          'A workout with this name already exists in this session',
          errors: {'exerciseName': 'Already exists'},
        );
      }

      final masterFid = newFirestoreId();
      final joinFid = newFirestoreId();
      final nextPosition = await sessionWorkoutDao.nextPosition(sessionId);

      final model = WorkoutModel(
        id: joinFid.hashCode,
        sessionId: sessionId.hashCode,
        workoutId: masterFid.hashCode,
        exerciseName: exerciseName,
        position: nextPosition,
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        defaultDurationSeconds: defaultDurationSeconds,
        defaultWeight: defaultWeight,
        notes: notes,
        firestoreId: joinFid,
        masterFirestoreId: masterFid,
        sessionFirestoreId: sessionId,
        createdAt: now,
        updatedAt: now,
      );

      // The repository layer fires `sync.uploadMasterWorkout` and
      // `sync.uploadSessionWorkout` after this method returns, so the
      // data source only needs to persist the join row (the DAO
      // uploadSessionWorkout already mirrors to Firestore).
      await sessionWorkoutDao.insertSessionWorkout(model);

      // Re-read so the returned model carries canonical Firestore
      // state.
      final fresh = await sessionWorkoutDao.getById(joinFid);
      return fresh ?? model;
    } catch (error) {
      throw DatabaseException(
        'Failed to add workout to session $sessionId: $error',
        cause: error,
      );
    }
  }

  Future<WorkoutModel> update({
    required String id,
    required String exerciseName,
    required int defaultSets,
    required int defaultReps,
    int? defaultDurationSeconds,
    double? defaultWeight,
    required String notes,
  }) async {
    try {
      final existing = await _resolveById(id);
      if (existing == null) {
        throw NotFoundException('SessionWorkout $id not found');
      }

      final sessionFid = existing.sessionFirestoreId ?? '';
      final existingRows = await sessionWorkoutDao.getBySession(sessionFid);
      final otherRows = existingRows.where((r) => r.id != existing.id).toList();
      final normalizedSearch = exerciseName.trim().toLowerCase();
      if (otherRows.any(
        (r) => r.exerciseName.trim().toLowerCase() == normalizedSearch,
      )) {
        throw const ValidationException(
          'A workout with this name already exists in this session',
          errors: {'exerciseName': 'Already exists'},
        );
      }

      final updated = existing.copyWithFields(
        exerciseName: exerciseName,
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        defaultDurationSeconds: defaultDurationSeconds,
        defaultWeight: defaultWeight,
        notes: notes,
        updatedAt: DateTime.now(),
      );
      await sessionWorkoutDao.updateSessionWorkout(updated);
      return updated;
    } catch (error) {
      throw DatabaseException(
        'Failed to update workout $id: $error',
        cause: error,
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      final existing = await _resolveById(id);
      if (existing == null) {
        // Nothing to do — already gone.
        return;
      }
      await sessionWorkoutDao.deleteById(existing.firestoreId!);
    } catch (error) {
      throw DatabaseException('Failed to delete workout $id', cause: error);
    }
  }

  Future<List<WorkoutModel>> reorder({
    required String sessionId,
    required List<String> orderedIds,
  }) async {
    try {
      await sessionWorkoutDao.reorderSession(
        sessionFirestoreId: sessionId,
        orderedIds: orderedIds,
      );
      // Read back the freshly-ordered rows so the repository can sync
      // each one (idempotently) to Firestore.
      final reordered = <WorkoutModel>[];
      for (final id in orderedIds) {
        final row = await sessionWorkoutDao.getById(id);
        if (row != null) reordered.add(row);
      }
      return reordered;
    } catch (error) {
      throw DatabaseException(
        'Failed to reorder workouts for session $sessionId',
        cause: error,
      );
    }
  }

  /// Bulk lookup by Firestore id. Used by the export service and
  /// history data source.
  Future<List<WorkoutModel>> getByIds(List<String> ids) async {
    try {
      if (ids.isEmpty) return const <WorkoutModel>[];
      return await workoutDao.getByIds(ids);
    } catch (error) {
      throw DatabaseException('Failed to load workouts by ids', cause: error);
    }
  }

  /// Bulk lookup by master workout Firestore id. Used by the history
  /// data source to resolve `WorkoutLogEntry.workoutFirestoreId` (which
  /// carries the masterFirestoreId, not the join row's own id) back
  /// into join rows so the calendar can render `exerciseName`.
  Future<List<WorkoutModel>> getByMasterIds(List<String> masterFids) async {
    try {
      if (masterFids.isEmpty) return const <WorkoutModel>[];
      return await workoutDao.getByMasterIds(masterFids);
    } catch (error) {
      throw DatabaseException(
        'Failed to load workouts by master ids',
        cause: error,
      );
    }
  }

  /// Returns the firestore id for every workout in the collection,
  /// keyed by its int hashCode (`Workout.workoutId`). Used by the
  /// prefill flow to map the int keys it receives into Firestore ids.
  Future<Map<int, String>> getAllWorkoutIds() async {
    try {
      final all = await workoutDao.getAllWorkouts();
      return <int, String>{
        for (final w in all)
          if (w.masterFirestoreId != null) w.workoutId: w.masterFirestoreId!,
      };
    } catch (error) {
      throw DatabaseException(
        'Failed to load workout id map',
        cause: error,
      );
    }
  }

  /// Resolves either a Firestore id (string) or an int hash derived
  /// from `firestoreId.hashCode` to a [WorkoutModel]. We pull the
  /// full sessionWorkouts collection because Firestore cannot index
  /// by int hash — only by document id.
  Future<WorkoutModel?> _resolveById(String id) async {
    // First try a direct Firestore document lookup (fast path for
    // callers that pass the actual doc id).
    final direct = await sessionWorkoutDao.getById(id);
    if (direct != null) return direct;
    // Otherwise, fall back to scanning for a matching int hash.
    final all = await workoutDao.getAllWorkouts();
    final intHash = int.tryParse(id);
    if (intHash != null) {
      for (final w in all) {
        if (w.id == intHash) return w;
      }
    }
    return null;
  }
}

/// (helper extensions below)

extension on WorkoutModel {
  WorkoutModel copyWithFields({
    String? exerciseName,
    int? defaultSets,
    int? defaultReps,
    int? defaultDurationSeconds,
    double? defaultWeight,
    String? notes,
    DateTime? updatedAt,
  }) {
    return WorkoutModel(
      id: id,
      sessionId: sessionId,
      workoutId: workoutId,
      exerciseName: exerciseName ?? this.exerciseName,
      position: position,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultDurationSeconds:
          defaultDurationSeconds ?? this.defaultDurationSeconds,
      defaultWeight: defaultWeight ?? this.defaultWeight,
      notes: notes ?? this.notes,
      firestoreId: firestoreId,
      masterFirestoreId: masterFirestoreId,
      sessionFirestoreId: sessionFirestoreId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}