import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/session_dao.dart';
import 'daos/workout_dao.dart';
import 'tables/sessions_table.dart';
import 'tables/workouts_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Sessions, Workouts], daos: [SessionDao, WorkoutDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(p.join(directory.path, 'fitness_diary.db'));

    return NativeDatabase(file);
  });
}
