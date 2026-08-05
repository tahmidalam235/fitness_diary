import 'dart:async';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../../domain/repositories/freeze_repository.dart';
import '../datasources/freeze_local_datasource.dart';

/// Concrete [FreezeRepository] backed by the local Drift DAO.
///
/// Maps any thrown [AppException] (or generic Object) into a
/// [Failure] so the presentation layer can handle it uniformly. Mirrors
/// the error-mapping style of `HistoryRepositoryImpl`.
class FreezeRepositoryImpl implements FreezeRepository {
  const FreezeRepositoryImpl({required this.dataSource});

  final FreezeLocalDataSource dataSource;

  Failure _mapError(Object error, String label) {
    return mapExceptionToFailure(
      error is AppException ? error : UnexpectedException(label, cause: error),
    );
  }

  @override
  Stream<Either<Failure, Set<DateTime>>> watchFrozenDays() async* {
    try {
      await for (final days in dataSource.watchFrozenDays()) {
        yield Right<Failure, Set<DateTime>>(days);
      }
    } catch (error) {
      yield Left<Failure, Set<DateTime>>(
        _mapError(error, 'Failed to watch frozen days'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> setFrozen(
    DateTime day, {
    required bool frozen,
  }) async {
    try {
      final normalized = DateTime(day.year, day.month, day.day);
      if (frozen) {
        await dataSource.insertFreeze(day: normalized);
      } else {
        await dataSource.deleteFreezeForDay(normalized);
      }
      return const Right<Failure, Unit>(Unit.instance);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (error) {
      return Left(
        UnexpectedFailure(message: 'Failed to update freeze', cause: error),
      );
    }
  }
}
