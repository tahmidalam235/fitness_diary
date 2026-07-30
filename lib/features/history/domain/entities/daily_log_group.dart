import 'package:equatable/equatable.dart';

import '../../../workout_log/domain/entities/workout_log.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';

/// A parent [WorkoutLog] and its child [WorkoutLogEntry]s for a single
/// day. The Daily Details page renders one of these per session
/// performed on that day.
class DailyLogGroup extends Equatable {
  const DailyLogGroup({required this.log, required this.entries});

  final WorkoutLog log;
  final List<WorkoutLogEntry> entries;

  @override
  List<Object?> get props => [log, entries];
}