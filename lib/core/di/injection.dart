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
}