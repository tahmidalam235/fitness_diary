import 'package:get_it/get_it.dart';

import '../../features/calendar/presentation/bloc/calendar_bloc.dart';
import '../../features/calendar/presentation/bloc/daily_details_bloc.dart';
import '../../features/history/data/datasources/history_local_datasource.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/domain/usecases/get_workouts_by_ids.dart';
import '../../features/history/domain/usecases/watch_entries_by_log_for_day.dart';
import '../../features/history/domain/usecases/watch_logs_for_day.dart';
import '../../features/history/domain/usecases/watch_logs_in_range.dart';
import '../../features/session/data/datasources/session_local_datasource.dart';
import '../../features/session/data/repositories/session_repository_impl.dart';
import '../../features/session/domain/repositories/session_repository.dart';
import '../../features/session/domain/usecases/create_session.dart';
import '../../features/session/domain/usecases/delete_session.dart';
import '../../features/session/domain/usecases/get_session_by_id.dart';
import '../../features/session/domain/usecases/get_sessions.dart';
import '../../features/session/domain/usecases/get_sessions_by_ids.dart';
import '../../features/session/domain/usecases/update_session.dart';
import '../../features/session/domain/usecases/watch_sessions.dart';
import '../../features/session/presentation/bloc/session_bloc.dart';
import '../../features/workout/data/datasources/workout_local_datasource.dart';
import '../../features/workout/data/repositories/workout_repository_impl.dart';
import '../../features/workout/domain/repositories/workout_repository.dart';
import '../../features/workout/domain/usecases/add_workout.dart';
import '../../features/workout/domain/usecases/delete_workout.dart';
import '../../features/workout/domain/usecases/reorder_workouts.dart';
import '../../features/workout/domain/usecases/update_workout.dart';
import '../../features/workout/domain/usecases/watch_workouts.dart';
import '../../features/workout/presentation/bloc/workout_list_bloc.dart';
import '../../features/workout_log/data/datasources/workout_log_local_datasource.dart';
import '../../features/workout_log/data/repositories/workout_log_repository_impl.dart';
import '../../features/workout_log/domain/repositories/workout_log_repository.dart';
import '../../features/workout_log/domain/usecases/add_workouts_to_today.dart';
import '../../features/workout_log/domain/usecases/delete_entry.dart';
import '../../features/workout_log/domain/usecases/get_last_entries_for_workouts.dart';
import '../../features/workout_log/domain/usecases/get_or_create_today_log.dart';
import '../../features/workout_log/domain/usecases/upsert_entry.dart';
import '../../features/workout_log/domain/usecases/watch_today_entries_by_workout.dart';
import '../../features/workout_log/presentation/bloc/workout_tracking_bloc.dart';
import '../../features/today/presentation/bloc/today_workouts_bloc.dart';
import '../database/daos/session_dao.dart';
import '../database/daos/session_workout_dao.dart';
import '../database/daos/workout_dao.dart';
import '../database/daos/workout_log_dao.dart';
import 'service_locator.dart';

/// Static registration helpers. Called from `injection.dart`.
///
/// Using explicit registration (instead of build_runner-generated
/// `injection.config.dart`) keeps the dependency graph fully readable
/// without an extra codegen pass.
extension InjectionConfig on GetIt {
  void registerCore() {
    registerLazySingleton<WorkoutDao>(() => WorkoutDao(getIt()));
    registerLazySingleton<WorkoutLogDao>(() => WorkoutLogDao(getIt()));
  }

  void registerSessionFeature() {
    registerLazySingleton<SessionDao>(() => SessionDao(getIt()));
    registerLazySingleton<SessionWorkoutDao>(
      () => SessionWorkoutDao(getIt()),
    );

    registerLazySingleton<SessionLocalDataSource>(
      () => SessionLocalDataSource(dao: getIt()),
    );

    registerLazySingleton<SessionRepository>(
      () => SessionRepositoryImpl(dataSource: getIt()),
    );

    registerLazySingleton<GetSessions>(
      () => GetSessions(repository: getIt()),
    );
    registerLazySingleton<WatchSessions>(
      () => WatchSessions(repository: getIt()),
    );
    registerLazySingleton<GetSessionById>(
      () => GetSessionById(repository: getIt()),
    );
    registerLazySingleton<GetSessionsByIds>(
      () => GetSessionsByIds(repository: getIt()),
    );
    registerLazySingleton<CreateSession>(
      () => CreateSession(repository: getIt()),
    );
    registerLazySingleton<UpdateSession>(
      () => UpdateSession(repository: getIt()),
    );
    registerLazySingleton<DeleteSession>(
      () => DeleteSession(repository: getIt()),
    );

    registerFactory<SessionBloc>(
      () => SessionBloc(
        getSessions: getIt(),
        watchSessions: getIt(),
        getSessionById: getIt(),
        createSession: getIt(),
        updateSession: getIt(),
        deleteSession: getIt(),
      ),
    );
  }

  void registerWorkoutFeature() {
    registerLazySingleton<WorkoutLocalDataSource>(
      () => WorkoutLocalDataSource(
        database: getIt(),
        sessionWorkoutDao: getIt(),
        workoutDao: getIt(),
        sessionDao: getIt(),
      ),
    );

    registerLazySingleton<WorkoutRepository>(
      () => WorkoutRepositoryImpl(dataSource: getIt()),
    );

    registerLazySingleton<WatchWorkoutsForSession>(
      () => WatchWorkoutsForSession(repository: getIt()),
    );
    registerLazySingleton<AddWorkoutToSession>(
      () => AddWorkoutToSession(repository: getIt()),
    );
    registerLazySingleton<UpdateWorkout>(
      () => UpdateWorkout(repository: getIt()),
    );
    registerLazySingleton<DeleteWorkout>(
      () => DeleteWorkout(repository: getIt()),
    );
    registerLazySingleton<ReorderWorkouts>(
      () => ReorderWorkouts(repository: getIt()),
    );

    registerFactory<WorkoutListBloc>(
      () => WorkoutListBloc(
        watchWorkouts: getIt(),
        addWorkout: getIt(),
        updateWorkout: getIt(),
        deleteWorkout: getIt(),
        reorderWorkouts: getIt(),
      ),
    );
  }

  void registerWorkoutLogFeature() {
    registerLazySingleton<WorkoutLogLocalDataSource>(
      () => WorkoutLogLocalDataSource(
        workoutLogDao: getIt(),
        sessionWorkoutDao: getIt(),
      ),
    );

    registerLazySingleton<WorkoutLogRepository>(
      () => WorkoutLogRepositoryImpl(dataSource: getIt()),
    );

    registerLazySingleton<GetOrCreateTodayLog>(
      () => GetOrCreateTodayLog(repository: getIt()),
    );
    registerLazySingleton<WatchTodayEntriesByWorkout>(
      () => WatchTodayEntriesByWorkout(repository: getIt()),
    );
    registerLazySingleton<UpsertEntry>(
      () => UpsertEntry(repository: getIt()),
    );
    registerLazySingleton<DeleteEntry>(
      () => DeleteEntry(repository: getIt()),
    );
    registerLazySingleton<GetLastEntriesForWorkouts>(
      () => GetLastEntriesForWorkouts(repository: getIt()),
    );
    registerLazySingleton<AddWorkoutsToToday>(
      () => AddWorkoutsToToday(repository: getIt()),
    );

    registerFactory<WorkoutTrackingBloc>(
      () => WorkoutTrackingBloc(
        getOrCreateTodayLog: getIt(),
        watchTodayEntriesByWorkout: getIt(),
        upsertEntry: getIt(),
        deleteEntry: getIt(),
        getLastEntriesForWorkouts: getIt(),
        addWorkoutsToToday: getIt(),
      ),
    );
  }

  void registerHistoryFeature() {
    registerLazySingleton<HistoryLocalDataSource>(
      () => HistoryLocalDataSource(
        workoutLogDao: getIt(),
        workoutLocalDataSource: getIt(),
      ),
    );

    registerLazySingleton<HistoryRepository>(
      () => HistoryRepositoryImpl(dataSource: getIt()),
    );

    registerLazySingleton<WatchLogsInRange>(
      () => WatchLogsInRange(repository: getIt()),
    );
    registerLazySingleton<WatchLogsForDay>(
      () => WatchLogsForDay(repository: getIt()),
    );
    registerLazySingleton<WatchEntriesByLogForDay>(
      () => WatchEntriesByLogForDay(repository: getIt()),
    );
    registerLazySingleton<GetWorkoutsByIds>(
      () => GetWorkoutsByIds(repository: getIt()),
    );
  }

  void registerCalendarFeature() {
    registerFactory<CalendarBloc>(
      () => CalendarBloc(watchLogsInRange: getIt()),
    );
    registerFactory<DailyDetailsBloc>(
      () => DailyDetailsBloc(
        watchLogsForDay: getIt(),
        watchEntriesByLogForDay: getIt(),
        getWorkoutsByIds: getIt(),
        getSessionsByIds: getIt(),
      ),
    );
  }

  void registerTodayFeature() {
    registerFactory<TodayWorkoutsBloc>(
      () => TodayWorkoutsBloc(
        watchTodayEntriesByWorkout: getIt(),
        getOrCreateTodayLog: getIt(),
        watchWorkoutsForSession: getIt(),
      ),
    );
  }
}