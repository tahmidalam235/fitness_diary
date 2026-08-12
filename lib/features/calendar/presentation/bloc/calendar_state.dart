import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

sealed class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => const [];
}

class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

class CalendarLoaded extends CalendarState {
  const CalendarLoaded({
    required this.daysWithLogs,
    required this.workoutsByDay,
  });

  /// Set of date-only values that have at least one completed log.
  final Set<DateTime> daysWithLogs;

  /// Map of date → count of logs performed that day.
  final Map<DateTime, int> workoutsByDay;

  @override
  List<Object?> get props => [daysWithLogs, workoutsByDay];
}

class CalendarError extends CalendarState {
  const CalendarError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
