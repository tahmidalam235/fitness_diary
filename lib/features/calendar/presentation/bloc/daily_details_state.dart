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
  });

  final DateTime date;
  final List<DailyLogGroup> groups;
  final Map<int, Workout> workoutsById;
  final Map<int, Session> sessionsById;

  DailyDetailsLoaded copyWith({
    DateTime? date,
    List<DailyLogGroup>? groups,
    Map<int, Workout>? workoutsById,
    Map<int, Session>? sessionsById,
  }) {
    return DailyDetailsLoaded(
      date: date ?? this.date,
      groups: groups ?? this.groups,
      workoutsById: workoutsById ?? this.workoutsById,
      sessionsById: sessionsById ?? this.sessionsById,
    );
  }

  @override
  List<Object?> get props => [date, groups, workoutsById, sessionsById];
}

class DailyDetailsEmpty extends DailyDetailsState {
  const DailyDetailsEmpty({required this.date});
  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class DailyDetailsError extends DailyDetailsState {
  const DailyDetailsError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
