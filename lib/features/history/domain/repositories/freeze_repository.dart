import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';

/// Read/write facade over the workout_log_freezes table.
///
/// Distinct from `HistoryRepository` (which only exposes read-side
/// range queries on logs/entries). Freeze is a tiny surface area, so
/// it lives in its own contract to avoid bloating the history
/// repository.
abstract class FreezeRepository {
  /// Reactive stream of every currently-frozen day, normalized to
  /// midnight local. Used by the streak calculator and the freeze
  /// page.
  Stream<Either<Failure, Set<DateTime>>> watchFrozenDays();

  /// Toggle the freeze state for [day]. When [frozen] is `true` a
  /// freeze row is inserted (idempotent); when `false` any existing
  /// freeze for that day is removed.
  Future<Either<Failure, Unit>> setFrozen(
    DateTime day, {
    required bool frozen,
  });
}
