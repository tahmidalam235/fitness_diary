import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../session/domain/entities/session.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../../features/history/domain/entities/daily_log_group.dart';

sealed class DailyDetailsState extends Equatable {
  const DailyDetailsState();

  @override
  List<Object?> get props => const [];
}

class DailyDetailsInitial extends DailyDetailsState {
  const DailyDetailsInitial();
}

class DailyDetailsLoading extends DailyDetailsState {
  const DailyDetailsLoading({required this.date});
  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class DailyDetailsLoaded extends DailyDetailsState {
  const DailyDetailsLoaded({
    required this.date,
    required this.groups,
    required this.workoutsById,
    required this.sessionsById,
    required this.isFrozen,
  });

  final DateTime date;
  final List<DailyLogGroup> groups;
  final Map<int, Workout> workoutsById;
  final Map<int, Session> sessionsById;

  /// Whether the selected date is marked as a freeze/rest day.
  final bool isFrozen;

  DailyDetailsLoaded copyWith({
    DateTime? date,
    List<DailyLogGroup>? groups,
    Map<int, Workout>? workoutsById,
    Map<int, Session>? sessionsById,
    bool? isFrozen,
  }) {
    return DailyDetailsLoaded(
      date: date ?? this.date,
      groups: groups ?? this.groups,
      workoutsById: workoutsById ?? this.workoutsById,
      sessionsById: sessionsById ?? this.sessionsById,
      isFrozen: isFrozen ?? this.isFrozen,
    );
  }

  @override
  List<Object?> get props => [date, groups, workoutsById, sessionsById, isFrozen];
}

class DailyDetailsEmpty extends DailyDetailsState {
  const DailyDetailsEmpty({required this.date, this.isFrozen = false});
  final DateTime date;

  /// Whether the selected date is marked as a freeze/rest day.
  final bool isFrozen;

  @override
  List<Object?> get props => [date, isFrozen];
}

class DailyDetailsError extends DailyDetailsState {
  const DailyDetailsError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
