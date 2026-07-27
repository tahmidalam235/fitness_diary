import 'package:drift/drift.dart';

class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sessionId => integer()();

  TextColumn get exerciseName => text()();

  IntColumn get sets => integer()();

  IntColumn get reps => integer()();

  RealColumn get weight => real().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
