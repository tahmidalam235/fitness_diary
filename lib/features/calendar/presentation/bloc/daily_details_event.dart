import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../session/domain/entities/session.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';

sealed class DailyDetailsEvent extends Equatable {
  const DailyDetailsEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the day selected in the URL. Cancels any previous subscriptions
/// before opening the new ones.
class DaySelectedEvent extends DailyDetailsEvent {
  const DaySelectedEvent(this.day);
  final DateTime day;

  @override
  List<Object?> get props => [day];
}

class LogsReceivedEvent extends DailyDetailsEvent {
  const LogsReceivedEvent(this.logs);
  final List<WorkoutLog> logs;

  @override
  List<Object?> get props => [logs];
}

class EntriesReceivedEvent extends DailyDetailsEvent {
  const EntriesReceivedEvent(this.entriesByLog);
  final Map<int, List<WorkoutLogEntry>> entriesByLog;

  @override
  List<Object?> get props => [entriesByLog];
}

class WorkoutsReceivedEvent extends DailyDetailsEvent {
  const WorkoutsReceivedEvent(this.workoutsById);
  final Map<int, Workout> workoutsById;

  @override
  List<Object?> get props => [workoutsById];
}

class SessionsReceivedEvent extends DailyDetailsEvent {
  const SessionsReceivedEvent(this.sessionsById);
  final Map<int, Session> sessionsById;

  @override
  List<Object?> get props => [sessionsById];
}

class DetailsErrorEvent extends DailyDetailsEvent {
  const DetailsErrorEvent(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
