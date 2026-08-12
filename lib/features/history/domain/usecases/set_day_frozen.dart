import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../../domain/repositories/freeze_repository.dart';

/// Parameters for [SetDayFrozen]: the [day] to toggle and the desired
/// [frozen] state.
class SetDayFrozenParams extends Params {
  const SetDayFrozenParams({required this.day, required this.frozen});

  final DateTime day;
  final bool frozen;

  @override
  List<Object?> get props => [day, frozen];
}

/// Toggles a day between frozen and not-frozen.
class SetDayFrozen extends UseCase<Unit, SetDayFrozenParams> {
  const SetDayFrozen({required this.repository});

  final FreezeRepository repository;

  @override
  Future<Either<Failure, Unit>> call(SetDayFrozenParams params) {
    return repository.setFrozen(params.day, frozen: params.frozen);
  }
}
