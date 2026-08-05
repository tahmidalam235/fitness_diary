import '../../features/auth/data/auth_service.dart';
import '../../features/profile/data/profile_service.dart';
import '../../features/settings/data/notification_service.dart';
import '../../features/settings/data/settings_service.dart';
import '../../features/settings/data/theme_service.dart';
import '../database/app_database.dart';
import 'injection.config.dart';
import 'service_locator.dart';

export 'service_locator.dart';

/// Eagerly initializes the dependency injection graph.
///
/// Must be awaited from `main()` before `runApp`.
Future<void> setupInjection() async {
  // Eager: open the database once so the app is responsive on first frame.
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // Lazy: register all DAOs, repositories, use cases, and blocs.
  getIt.registerCore();
  getIt.registerSessionFeature();
  getIt.registerWorkoutFeature();
  getIt.registerWorkoutLogFeature();
  getIt.registerHistoryFeature();
  getIt.registerCalendarFeature();
  getIt.registerTodayFeature();
  getIt.registerAuthFeature();
  getIt.registerSettingsFeature();

  // Eagerly load persisted preferences + auth state before the UI
  // draws, ensuring the router redirect and theme selection work
  // on the very first frame.
  await getIt<AuthService>().load();
  await getIt<SettingsService>().load();
  await getIt<ThemeService>().load();
  await getIt<ProfileService>().load();
  await getIt<NotificationService>().init();
}
