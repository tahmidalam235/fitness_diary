import 'package:fitness_diary/core/error/failure.dart';
import 'package:fitness_diary/core/utils/either.dart';
import 'package:fitness_diary/features/calendar/presentation/bloc/daily_details_bloc.dart';
import 'package:fitness_diary/features/calendar/presentation/bloc/daily_details_event.dart';
import 'package:fitness_diary/features/calendar/presentation/bloc/daily_details_state.dart';
import 'package:fitness_diary/features/history/domain/usecases/get_workouts_by_ids.dart';
import 'package:fitness_diary/features/history/domain/usecases/watch_entries_by_log_for_day.dart';
import 'package:fitness_diary/features/history/domain/usecases/watch_logs_for_day.dart';
import 'package:fitness_diary/features/session/domain/entities/session.dart';
import 'package:fitness_diary/features/session/domain/usecases/get_sessions_by_ids.dart';
import 'package:fitness_diary/features/workout/domain/entities/workout.dart';
import 'package:fitness_diary/features/workout_log/domain/entities/workout_log.dart';
import 'package:fitness_diary/features/workout_log/domain/entities/workout_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchLogs extends Mock implements WatchLogsForDay {}

class _MockWatchEntries extends Mock
    implements WatchEntriesByLogForDay {}

class _MockGetWorkouts extends Mock implements GetWorkoutsByIds {}

class _MockGetSessions extends Mock implements GetSessionsByIds {}

void main() {
  late _MockWatchLogs watchLogs;
  late _MockWatchEntries watchEntries;
  late _MockGetWorkouts getWorkouts;
  late _MockGetSessions getSessions;

  setUpAll(() {
    registerFallbackValue(<int>[]);
  });

  setUp(() {
    watchLogs = _MockWatchLogs();
    watchEntries = _MockWatchEntries();
    getWorkouts = _MockGetWorkouts();
    getSessions = _MockGetSessions();

    when(() => watchLogs(any())).thenAnswer(
      (_) => Stream.value(const Right<Failure, List<WorkoutLog>>([])),
    );
    when(() => watchEntries(any())).thenAnswer(
      (_) => Stream.value(
        const Right<Failure, Map<int, List<WorkoutLogEntry>>>({}),
      ),
    );
    when(() => getWorkouts(any())).thenAnswer(
      (_) async => const Right<Failure, Map<int, Workout>>({}),
    );
    when(() => getSessions(any())).thenAnswer(
      (_) async => const Right<Failure, Map<int, Session>>({}),
    );
  });

  test('emits DailyDetailsEmpty when both streams emit empty', () async {
    final bloc = DailyDetailsBloc(
      watchLogsForDay: watchLogs,
      watchEntriesByLogForDay: watchEntries,
      getWorkoutsByIds: getWorkouts,
      getSessionsByIds: getSessions,
    );
    bloc.add(DaySelectedEvent(DateTime(2026, 7, 15)));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state, isA<DailyDetailsEmpty>());
    await bloc.close();
  });

  test('emits DailyDetailsLoaded when both streams emit a log + entries',
      () async {
    final log = WorkoutLog(
      id: 1,
      sessionId: 7,
      performedAt: DateTime(2026, 7, 15),
    );
    final entry = WorkoutLogEntry(
      id: 10,
      workoutLogId: 1,
      workoutId: 5,
      setIndex: 1,
      position: 0,
      reps: 10,
      weight: 60.0,
    );
    when(() => watchLogs(any())).thenAnswer(
      (_) => Stream.value(Right<Failure, List<WorkoutLog>>([log])),
    );
    when(() => watchEntries(any())).thenAnswer(
      (_) => Stream.value(
        Right<Failure, Map<int, List<WorkoutLogEntry>>>({1: [entry]}),
      ),
    );

    final bloc = DailyDetailsBloc(
      watchLogsForDay: watchLogs,
      watchEntriesByLogForDay: watchEntries,
      getWorkoutsByIds: getWorkouts,
      getSessionsByIds: getSessions,
    );
    bloc.add(DaySelectedEvent(DateTime(2026, 7, 15)));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state, isA<DailyDetailsLoaded>());
    final loaded = bloc.state as DailyDetailsLoaded;
    expect(loaded.groups, hasLength(1));
    expect(loaded.groups.first.entries, hasLength(1));
    await bloc.close();
  });
}