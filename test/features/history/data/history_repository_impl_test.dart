import 'package:fitness_diary/core/error/exceptions.dart';
import 'package:fitness_diary/core/error/failure.dart';
import 'package:fitness_diary/features/history/data/datasources/history_local_datasource.dart';
import 'package:fitness_diary/features/history/data/repositories/history_repository_impl.dart';
import 'package:fitness_diary/features/workout/data/models/workout_model.dart';
import 'package:fitness_diary/features/workout_log/data/models/workout_log_model.dart';
import 'package:fitness_diary/features/workout_log/domain/entities/workout_log_entry.dart'
    as entity;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements HistoryLocalDataSource {}

void main() {
  late HistoryRepositoryImpl repo;
  late _MockDataSource ds;

  setUp(() {
    ds = _MockDataSource();
    repo = HistoryRepositoryImpl(dataSource: ds);
  });

  group('HistoryRepositoryImpl.watchLogsInRange', () {
    final start = DateTime(2026, 7, 1);
    final end = DateTime(2026, 8, 1);

    test('returns Right with mapped entities on success', () async {
      final logModel = WorkoutLogModel(
        id: 1,
        sessionId: 7,
        performedAt: DateTime(2026, 7, 15),
      );
      when(
        () => ds.watchLogsInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) => Stream<List<WorkoutLogModel>>.value([logModel]));

      final stream = repo.watchLogsInRange(start: start, end: end);
      final result = await stream.first;

      expect(result.isRight, isTrue);
      result.fold((_) => fail('expected Right'), (logs) {
        expect(logs, hasLength(1));
        expect(logs.first.id, 1);
        expect(logs.first.sessionId, 7);
      });
    });

    test('returns Left when datasource throws', () async {
      when(
        () => ds.watchLogsInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer(
        (_) => Stream<List<WorkoutLogModel>>.error(
          const DatabaseException('boom'),
        ),
      );

      final stream = repo.watchLogsInRange(start: start, end: end);
      final results = await stream.toList();
      expect(results, hasLength(1));
      expect(results.first.isLeft, isTrue);
      results.first.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('HistoryRepositoryImpl.watchLogsForDay', () {
    test('emits empty list wrapped in Right', () async {
      when(
        () => ds.watchLogsForDay(any()),
      ).thenAnswer((_) => Stream<List<WorkoutLogModel>>.value(const []));
      final result = await repo.watchLogsForDay(DateTime(2026, 7, 15)).first;
      expect(result.isRight, isTrue);
      result.fold((_) => fail('expected Right'), (logs) {
        expect(logs, isEmpty);
      });
    });
  });

  group('HistoryRepositoryImpl.watchEntriesByLogForDay', () {
    test('groups entries by log id', () async {
      final entry = entity.WorkoutLogEntry(
        id: 11,
        workoutLogId: 1,
        workoutId: 5,
        setIndex: 1,
        position: 0,
        reps: 10,
        weight: 60.0,
      );
      when(() => ds.watchEntriesByLogForDay(any())).thenAnswer(
        (_) => Stream<Map<String, List<entity.WorkoutLogEntry>>>.value({
          '1': [entry],
        }),
      );
      final result = await repo
          .watchEntriesByLogForDay(DateTime(2026, 7, 15))
          .first;
      expect(result.isRight, isTrue);
      result.fold((_) => fail('expected Right'), (map) {
        // The repository keys on `logFid.hashCode` (the int the domain
        // layer stores as `WorkoutLog.id`), so look up by that.
        final key = '1'.hashCode;
        expect(map[key], hasLength(1));
        expect(map[key]!.first.reps, 10);
      });
    });
  });

  group('HistoryRepositoryImpl.getWorkoutsByIds', () {
    test('returns empty map for empty ids', () async {
      final result = await repo.getWorkoutsByIds(const <int>[]);
      expect(result.isRight, isTrue);
      result.fold((_) => fail('expected Right'), (map) {
        expect(map, isEmpty);
      });
      verifyNever(() => ds.getWorkoutsByIds(any()));
    });

    test('returns Right with mapped workout map', () async {
      final model = WorkoutModel(
        id: 1,
        sessionId: 0,
        workoutId: 5,
        exerciseName: 'Bench Press',
        position: 0,
        defaultSets: 0,
        defaultReps: 0,
        defaultDurationSeconds: null,
        defaultWeight: null,
        notes: '',
        masterFirestoreId: 'master-5',
      );
      when(
        () => ds.getWorkoutsByIds(any()),
      ).thenAnswer((_) async => <WorkoutModel>[model]);
      when(() => ds.getAllWorkoutFirestoreIds()).thenAnswer(
        (_) async => <int, String>{5: 'master-5'},
      );

      final result = await repo.getWorkoutsByIds([5]);
      expect(result.isRight, isTrue);
      result.fold((_) => fail('expected Right'), (map) {
        expect(map[5]?.exerciseName, 'Bench Press');
      });
    });
  });
}
