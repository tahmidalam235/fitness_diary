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
  const CalendarLoading({required this.visibleMonth});
  final DateTime visibleMonth;

  @override
  List<Object?> get props => [visibleMonth];
}

class CalendarLoaded extends CalendarState {
  const CalendarLoaded({
    required this.visibleMonth,
    required this.daysWithLogs,
    required this.workoutsByDay,
  });

  /// First day (midnight) of the visible month.
  final DateTime visibleMonth;

  /// Set of date-only values that have at least one completed log.
  final Set<DateTime> daysWithLogs;

  /// Map of date → count of logs performed that day.
  final Map<DateTime, int> workoutsByDay;

  /// Convenience for "Today" button visibility.
  bool get isCurrentMonth {
    final now = DateTime.now();
    return visibleMonth.year == now.year && visibleMonth.month == now.month;
  }

  CalendarLoaded copyWith({
    DateTime? visibleMonth,
    Set<DateTime>? daysWithLogs,
    Map<DateTime, int>? workoutsByDay,
  }) {
    return CalendarLoaded(
      visibleMonth: visibleMonth ?? this.visibleMonth,
      daysWithLogs: daysWithLogs ?? this.daysWithLogs,
      workoutsByDay: workoutsByDay ?? this.workoutsByDay,
    );
  }

  @override
  List<Object?> get props => [visibleMonth, daysWithLogs, workoutsByDay];
}

class CalendarError extends CalendarState {
  const CalendarError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}