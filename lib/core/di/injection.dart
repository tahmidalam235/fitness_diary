import 'package:get_it/get_it.dart';

import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/calendar/presentation/bloc/calendar_bloc.dart';
import '../../features/calendar/presentation/bloc/daily_details_bloc.dart';
import '../../features/history/data/datasources/freeze_local_datasource.dart';
import '../../features/history/data/datasources/history_local_datasource.dart';
import '../../features/history/data/repositories/freeze_repository_impl.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/freeze_repository.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/domain/usecases/get_workouts_by_ids.dart';
import '../../features/history/domain/usecases/set_day_frozen.dart';
import '../../features/history/domain/usecases/watch_entries_by_log_for_day.dart';
import '../../features/history/domain/usecases/watch_frozen_days.dart';
import '../../features/history/domain/usecases/watch_logs_for_day.dart';
import '../../features/history/domain/usecases/watch_logs_in_range.dart';
import '../../features/profile/data/profile_service.dart';
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
import '../../features/settings/data/notification_service.dart';
import '../../features/settings/data/settings_service.dart';
import '../../features/settings/data/theme_service.dart';
import '../../features/today/presentation/bloc/today_workouts_bloc.dart';
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
import '../../features/workout_log/domain/usecases/find_today_log.dart';
import '../../features/workout_log/domain/usecases/get_last_entries_for_workouts.dart';
import '../../features/workout_log/domain/usecases/get_or_create_today_log.dart';
import '../../features/workout_log/domain/usecases/upsert_entry.dart';
import '../../features/workout_log/domain/usecases/watch_today_entries_by_workout.dart';
import '../../features/workout_log/presentation/bloc/workout_tracking_bloc.dart';
import '../database/daos/session_dao.dart';
import '../database/daos/session_workout_dao.dart';
import '../database/daos/workout_dao.dart';
import '../database/daos/workout_log_dao.dart';
import '../database/daos/workout_log_freeze_dao.dart';
import '../sync/sync_service.dart';
import '../sync/sync_status.dart';
import 'service_locator.dart';

export 'service_locator.dart';

/// Eagerly initializes the dependency injection graph.
///
/// Must be awaited from `main()` before `runApp`.
Future<void> setupInjection() async {
  // Lazy: register sync, DAOs, repositories, use cases, and blocs.
  getIt.registerCore();
  // Sync must register BEFORE the feature containers so that the
  // session/workout/log/history repositories can inject it.
  getIt.registerSyncFeature();
  getIt.registerSessionFeature();
  getIt.registerWorkoutFeature();
  getIt.registerWorkoutLogFeature();
  getIt.registerHistoryFeature();
  getIt.registerCalendarFeature();
  getIt.registerTodayFeature();
  getIt.registerSettingsFeature();
  getIt.registerAuthFeature();

  // Eagerly load persisted preferences + auth state before the UI
  // draws, ensuring the router redirect and theme selection work
  // on the very first frame.
  await getIt<AuthService>().load();
  await getIt<SettingsService>().load();
  await getIt<ThemeService>().load();
  await getIt<ProfileService>().load();
  await getIt<NotificationService>().init();
}

/// Static registration helpers. Manual (no build_runner) so the
/// dependency graph is fully readable without a codegen pass.
extension InjectionConfig on GetIt {
  void registerCore() {
    registerLazySingleton<SyncStatusController>(() => SyncStatusController());
    registerLazySingleton<SyncService>(
      () => SyncService(statusController: getIt<SyncStatusController>()),
    );
    // DAOs are now plain Firestore-backed classes that take a
    // SyncService. They keep their old names so existing call sites
    // don't have to change.
    registerLazySingleton<WorkoutDao>(() => WorkoutDao(getIt()));
    registerLazySingleton<WorkoutLogDao>(() => WorkoutLogDao(getIt()));
    registerLazySingleton<WorkoutLogFreezeDao>(
      () => WorkoutLogFreezeDao(getIt()),
    );
  }

  void registerSessionFeature() {
    registerLazySingleton<SessionDao>(() => SessionDao(getIt()));
    registerLazySingleton<SessionWorkoutDao>(() => SessionWorkoutDao(getIt()));

    registerLazySingleton<SessionLocalDataSource>(
      () => SessionLocalDataSource(dao: getIt()),
    );

    registerLazySingleton<SessionRepository>(
      () => SessionRepositoryImpl(
        dataSource: getIt(),
        sync: getIt<SyncService>(),
      ),
    );

    registerLazySingleton<GetSessions>(() => GetSessions(repository: getIt()));
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
        watchAllWorkouts: getIt(),
      ),
    );
  }

  void registerWorkoutFeature() {
    registerLazySingleton<WorkoutLocalDataSource>(
      () => WorkoutLocalDataSource(
        sessionWorkoutDao: getIt(),
        workoutDao: getIt(),
        sessionDao: getIt(),
      ),
    );

    registerLazySingleton<WorkoutRepository>(
      () => WorkoutRepositoryImpl(
        dataSource: getIt(),
        sessionDataSource: getIt(),
        sync: getIt<SyncService>(),
      ),
    );

    registerLazySingleton<WatchWorkoutsForSession>(
      () => WatchWorkoutsForSession(repository: getIt()),
    );
    registerLazySingleton<WatchAllWorkouts>(
      () => WatchAllWorkouts(repository: getIt()),
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
        workoutLocalDataSource: getIt(),
        sessionDao: getIt(),
      ),
    );

    registerLazySingleton<WorkoutLogRepository>(
      () => WorkoutLogRepositoryImpl(
        dataSource: getIt(),
        sessionDataSource: getIt(),
        workoutLocalDataSource: getIt(),
        sync: getIt<SyncService>(),
      ),
    );

    registerLazySingleton<GetOrCreateTodayLog>(
      () => GetOrCreateTodayLog(repository: getIt()),
    );
    registerLazySingleton<FindTodayLog>(
      () => FindTodayLog(repository: getIt()),
    );
    registerLazySingleton<WatchTodayEntriesByWorkout>(
      () => WatchTodayEntriesByWorkout(repository: getIt()),
    );
    registerLazySingleton<UpsertEntry>(() => UpsertEntry(repository: getIt()));
    registerLazySingleton<DeleteEntry>(() => DeleteEntry(repository: getIt()));
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

    // Freeze sub-feature
    registerLazySingleton<FreezeLocalDataSource>(
      () => FreezeLocalDataSource(dao: getIt()),
    );
    registerLazySingleton<FreezeRepository>(
      () => FreezeRepositoryImpl(
        dataSource: getIt(),
        sync: getIt<SyncService>(),
      ),
    );
    registerLazySingleton<WatchFrozenDays>(
      () => WatchFrozenDays(repository: getIt()),
    );
    registerLazySingleton<SetDayFrozen>(
      () => SetDayFrozen(repository: getIt()),
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
        findTodayLog: getIt(),
        watchWorkoutsForSession: getIt(),
      ),
    );
  }

  void registerAuthFeature() {
    registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
    registerLazySingleton<AuthService>(
      () => AuthService(repository: getIt()),
    );
  }

  void registerSettingsFeature() {
    registerLazySingleton<ProfileService>(
      () => ProfileService(sync: getIt<SyncService>()),
    );
    registerLazySingleton<SettingsService>(
      () => SettingsService(sync: getIt<SyncService>()),
    );
    registerLazySingleton<ThemeService>(() => ThemeService());
    registerLazySingleton<NotificationService>(() => NotificationService());
  }

  /// Registers the cloud-sync layer. Must be called BEFORE any feature
  /// that injects [SyncService].
  void registerSyncFeature() {
    // The sync layer is already registered in `registerCore()` so the
    // DAOs (which depend on it) can be built lazily. Kept here as a
    // no-op hook so feature modules can continue to call it in the
    // same order as before.
  }
}