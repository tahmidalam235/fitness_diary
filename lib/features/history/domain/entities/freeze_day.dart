import 'package:equatable/equatable.dart';

/// Domain entity for a single frozen calendar day.
///
/// A [FreezeDay] marks an intentional rest day so the streak counter
/// in the Progress section doesn't reset on days the user didn't
/// train. Equality compares by [day] alone so callers can put them in
/// a `Set` for fast membership tests.
class FreezeDay extends Equatable {
  const FreezeDay({required this.day, this.note = ''});

  /// Calendar day, normalized to midnight local time.
  final DateTime day;

  /// Optional free-text reason ("travel", "sick", "rest").
  final String note;

  FreezeDay copyWith({DateTime? day, String? note}) {
    return FreezeDay(day: day ?? this.day, note: note ?? this.note);
  }

  @override
  List<Object?> get props => [day, note];
}
