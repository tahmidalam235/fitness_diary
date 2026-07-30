import 'package:equatable/equatable.dart';

/// Aggregated view of a single calendar day for the history grid.
///
/// Built by the calendar bloc from the streamed [WorkoutLog]s so the UI
/// can render one indicator per day (the dot, the count, etc.).
class HistoryDay extends Equatable {
  const HistoryDay({
    required this.date,
    required this.workoutCount,
    required this.logIds,
  });

  /// Local date-only (midnight). Equality compares by [date] alone so
  /// callers can put [HistoryDay]s in a `Set` keyed by day.
  final DateTime date;
  final int workoutCount;
  final List<int> logIds;

  @override
  List<Object?> get props => [date, workoutCount, logIds];
}