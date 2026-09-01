import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_diary/core/database/daos/workout_log_dao.dart';
import 'package:fitness_diary/core/error/failure.dart';
import 'package:fitness_diary/core/utils/either.dart';
import 'package:fitness_diary/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:fitness_diary/features/calendar/presentation/bloc/calendar_state.dart';
import 'package:fitness_diary/features/history/domain/usecases/watch_logs_in_range.dart';
import 'package:fitness_diary/features/workout_log/domain/entities/workout_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchLogsInRange extends Mock implements WatchLogsInRange {}

class _MockWorkoutLogDao extends Mock implements WorkoutLogDao {}

void main() {
  late _MockWatchLogsInRange watchLogsInRange;
  late _MockWorkoutLogDao workoutLogDao;

  setUpAll(() {
    registerFallbackValue(DateRange(
      start: DateTime(2000),
      end: DateTime(2001),
    ));
  });

  setUp(() {
    watchLogsInRange = _MockWatchLogsInRange();
    workoutLogDao = _MockWorkoutLogDao();
    when(() => watchLogsInRange(any())).thenAnswer(
      (_) => Stream.value(const Right<Failure, List<WorkoutLog>>([])),
    );
    when(() => workoutLogDao.watchAllEntries()).thenAnswer(
      (_) => Stream.value(const []),
    );
  });

  blocTest<CalendarBloc, CalendarState>(
    'emits CalendarLoaded with empty data when stream emits empty',
    setUp: () {
      when(() => watchLogsInRange(any())).thenAnswer(
        (_) => Stream.value(const Right<Failure, List<WorkoutLog>>([])),
      );
    },
    build: () => CalendarBloc(
      watchLogsInRange: watchLogsInRange,
      workoutLogDao: workoutLogDao,
    ),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state, isA<CalendarLoaded>());
      final loaded = bloc.state as CalendarLoaded;
      expect(loaded.daysWithLogs, isEmpty);
      expect(loaded.workoutsByDay, isEmpty);
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'emits CalendarLoaded with a day set when stream emits one log',
    setUp: () {
      final today = DateTime.now();
      final log = WorkoutLog(
        id: 1,
        sessionId: 7,
        performedAt: today,
      );
      when(() => watchLogsInRange(any())).thenAnswer(
        (_) => Stream.value(Right<Failure, List<WorkoutLog>>([log])),
      );
    },
    build: () => CalendarBloc(
      watchLogsInRange: watchLogsInRange,
      workoutLogDao: workoutLogDao,
    ),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state, isA<CalendarLoaded>());
      final loaded = bloc.state as CalendarLoaded;
      expect(loaded.daysWithLogs.length, 1);
      // No entries seeded, so per-day counts should be empty even
      // though daysWithLogs surfaces the log-only day.
      expect(loaded.workoutsByDay, isEmpty);
    },
  );
}