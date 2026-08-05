import '../../../../core/error/failure.dart';
import '../../../../core/usecase/no_params.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../domain/repositories/freeze_repository.dart';

/// Streams the set of currently-frozen calendar days. Consumed by both
/// the streak calculator (in the Progress section) and the freeze page
/// (for its toggle strip).
class WatchFrozenDays extends StreamUseCase<Set<DateTime>, NoParams> {
  const WatchFrozenDays({required this.repository});

  final FreezeRepository repository;

  @override
  Stream<Either<Failure, Set<DateTime>>> call(NoParams params) {
    return repository.watchFrozenDays();
  }
}