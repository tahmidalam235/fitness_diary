import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

sealed class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => const [];
}

/// Internal: emitted by the stream listener when a new batch of logs is
/// received from the database.
class LogsReceivedEvent extends CalendarEvent {
  const LogsReceivedEvent(this.daysWithLogs, this.workoutsByDay);
  final Set<DateTime> daysWithLogs;
  final Map<DateTime, int> workoutsByDay;

  @override
  List<Object?> get props => [daysWithLogs, workoutsByDay];
}

/// Internal: emitted when the watched stream returns a [Failure].
class CalendarErrorEvent extends CalendarEvent {
  const CalendarErrorEvent(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
