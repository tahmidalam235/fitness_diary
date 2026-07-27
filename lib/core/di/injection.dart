import 'package:get_it/get_it.dart';

import '../database/app_database.dart';
import '../database/daos/session_dao.dart';
import '../database/daos/workout_dao.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupInjection() async {
  final database = AppDatabase();

  getIt.registerSingleton<AppDatabase>(database);

  getIt.registerLazySingleton<SessionDao>(() => SessionDao(database));

  getIt.registerLazySingleton<WorkoutDao>(() => WorkoutDao(database));
}
