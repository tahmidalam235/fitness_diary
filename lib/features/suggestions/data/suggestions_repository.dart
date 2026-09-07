import 'package:flutter/foundation.dart';

import '../../../core/di/injection.dart';
import '../../history/data/datasources/history_local_datasource.dart';
import '../../history/domain/usecases/get_workouts_by_ids.dart';
import '../../history/domain/usecases/watch_logs_in_range.dart';
import '../../workout/domain/entities/body_part.dart';
import '../../workout/domain/entities/workout.dart';
import '../../workout_log/domain/entities/workout_log.dart';
import '../../workout_log/domain/entities/workout_log_entry.dart';

/// One suggested workout to re-train.
@immutable
class SuggestedWorkout {
  const SuggestedWorkout({
    required this.workoutId,
    required this.name,
    required this.bodyPart,
    required this.timesPerformedLast30Days,
    required this.lastPerformedAt,
  });

  /// Master workout int id (stable across the app).
  final int workoutId;

  /// Exercise name shown to the user. Falls back to "Workout" when
  /// the master row has no name (legacy data).
  final String name;

  /// The targeted body part attached when the workout was created.
  /// Null when the workout was created before that field existed or
  /// the user explicitly cleared it — those rows simply don't make
  /// the cut for body-part-aware suggestions.
  final BodyPart? bodyPart;

  /// How many times the user performed this exact workout during
  /// the past 30 days. Drives the priority sort.
  final int timesPerformedLast30Days;

  /// Calendar day of the most recent performance.
  final DateTime lastPerformedAt;
}

/// Streams [SuggestedWorkout]s that qualify for the Suggestions page.
///
/// Algorithm (per the feature spec):
/// 1. Pull every workout log performed during the **previous 30 days**
///    (excluding today).
/// 2. For each log, collect its entries and resolve the master
///    workout to read `exerciseName` and `targetedBodyPart`.
/// 3. Aggregate per workout id: count + most-recent `performedAt`.
/// 4. Keep only those whose last performance was **more than 3 days
///    ago** (i.e. not in the previous 3 calendar days).
/// 5. Sort by frequency desc — more-frequent workouts surface first.
class SuggestionsRepository {
  SuggestionsRepository({
    HistoryLocalDataSource? dataSource,
    WatchLogsInRange? watchLogsInRange,
    GetWorkoutsByIds? getWorkoutsByIds,
  })  : _dataSource = dataSource ?? getIt<HistoryLocalDataSource>(),
        _watchLogsInRange =
            watchLogsInRange ?? getIt<WatchLogsInRange>(),
        _getWorkoutsByIds =
            getWorkoutsByIds ?? getIt<GetWorkoutsByIds>();

  final HistoryLocalDataSource _dataSource;
  final WatchLogsInRange _watchLogsInRange;
  final GetWorkoutsByIds _getWorkoutsByIds;

  /// Emits the current list of qualifying suggestions. Recomputes
  /// whenever the underlying 30-day logs or entries change.
  Stream<List<SuggestedWorkout>> watchSuggestions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Previous 30 days: [today - 30, today). "Previous" is historical
    // so today itself is excluded.
    final rangeStart = today.subtract(const Duration(days: 30));
    final rangeEnd = today;
    // Previous 3 days boundary: any performance on or after this
    // boundary counts as "recent enough" and excludes the workout.
    final recentBoundary = today.subtract(const Duration(days: 3));

    final logsStream = _watchLogsInRange(
      DateRange(start: rangeStart, end: rangeEnd),
    );

    // Logs drive the recompute; entries are streamed once per emission
    // so the join stays consistent with the logs snapshot.
    return logsStream.asyncMap((logsEither) async {
      final logs = logsEither.getOrElse((_) => const <WorkoutLog>[]);
      if (logs.isEmpty) return const <SuggestedWorkout>[];

      final logFidToLog = <String, WorkoutLog>{
        for (final l in logs)
          if (l.firestoreId != null) l.firestoreId!: l,
      };
      final logIds = logFidToLog.keys.toSet();

      final entriesEither = await _dataSource
          .watchAllEntries()
          .first
          .then((value) => value)
          .catchError((Object _) => const <WorkoutLogEntry>[]);
      final entries = entriesEither;

      // Resolve the master workouts so we can read name + body part.
      final distinctIds = <int>{
        for (final e in entries) e.workoutId,
      }..remove(0);
      final workoutsEither = await _getWorkoutsByIds(distinctIds.toList());
      final workoutsById =
          workoutsEither.getOrElse((_) => const <int, Workout>{});

      return _build(
        entries: entries,
        logFidToLog: logFidToLog,
        logIds: logIds,
        workoutsById: workoutsById,
        recentBoundary: recentBoundary,
      );
    });
  }

  /// Pure aggregation — exposed at package-private level so the page
  /// can unit-test it without standing up streams.
  static List<SuggestedWorkout> _build({
    required List<WorkoutLogEntry> entries,
    required Map<String, WorkoutLog> logFidToLog,
    required Set<String> logIds,
    required Map<int, Workout> workoutsById,
    required DateTime recentBoundary,
  }) {
    // Aggregate per workout id: count + most-recent `performedAt`.
    final counts = <int, int>{};
    final lastPerformed = <int, DateTime>{};
    for (final e in entries) {
      final logFid = e.workoutLogFirestoreId;
      if (logFid == null || !logIds.contains(logFid)) continue;
      final log = logFidToLog[logFid];
      if (log == null) continue;
      counts[e.workoutId] = (counts[e.workoutId] ?? 0) + 1;
      final prev = lastPerformed[e.workoutId];
      final performed = log.performedAt;
      if (prev == null || performed.isAfter(prev)) {
        lastPerformed[e.workoutId] = performed;
      }
    }

    final suggestions = <SuggestedWorkout>[];
    for (final entry in counts.entries) {
      final workoutId = entry.key;
      final last = lastPerformed[workoutId];
      if (last == null) continue;
      // Skip anything trained within the previous 3 days.
      if (!last.isBefore(recentBoundary)) continue;
      final workout = workoutsById[workoutId];
      final name = workout?.exerciseName.isNotEmpty == true
          ? workout!.exerciseName
          : 'Workout';
      suggestions.add(
        SuggestedWorkout(
          workoutId: workoutId,
          name: name,
          bodyPart: workout?.targetedBodyPart,
          timesPerformedLast30Days: entry.value,
          lastPerformedAt: last,
        ),
      );
    }

    // Sort serially by last-performed date descending — most recently
    // trained (but still past the 3-day boundary) sits at the top.
    suggestions.sort(
      (a, b) => b.lastPerformedAt.compareTo(a.lastPerformedAt),
    );
    return suggestions;
  }
}
