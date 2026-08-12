import 'dart:async';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/unit.dart';
import '../../domain/repositories/freeze_repository.dart';
import '../datasources/freeze_local_datasource.dart';

/// Firestore-backed implementation of [FreezeRepository].
///
/// The DAO already mirrors freeze writes to Firestore via [SyncService]
/// (insert/delete methods on `WorkoutLogFreezeDao`), so this repo just
/// passes through and surfaces failures as [Failure]s.
class FreezeRepositoryImpl implements FreezeRepository {
  const FreezeRepositoryImpl({required this.dataSource, this.sync});

  final FreezeLocalDataSource dataSource;
  final SyncService? sync;

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
        // The DAO's `insertFreeze` already uploads to Firestore on
        // success; the sync handle here is a defensive re-emit.
        unawaited(sync?.uploadFreezeForDay(normalized));
      } else {
        // The DAO's `deleteFreezeForDay` already deletes the
        // matching Firestore docs.
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

extension on SyncService {
  /// Defensive re-emit: look up the (already-persisted) freeze row for
  /// [day] and re-upload it. Idempotent — Firestore's `set` overwrites
  /// with identical data.
  Future<void> uploadFreezeForDay(DateTime day) async {
    final rows = await selectFreezesForDay(day);
    for (final row in rows) {
      await uploadFreeze(row);
    }
  }
}