import 'package:fitness_diary/core/error/exceptions.dart';
import 'package:fitness_diary/core/error/failure.dart';
import 'package:fitness_diary/core/utils/unit.dart';
import 'package:fitness_diary/features/session/data/datasources/session_local_datasource.dart';
import 'package:fitness_diary/features/session/data/models/session_model.dart';
import 'package:fitness_diary/features/session/data/repositories/session_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionLocalDataSource extends Mock
    implements SessionLocalDataSource {}

void main() {
  late _MockSessionLocalDataSource dataSource;
  late SessionRepositoryImpl repository;

  setUp(() {
    dataSource = _MockSessionLocalDataSource();
    repository = SessionRepositoryImpl(dataSource: dataSource);
  });

  group('SessionRepositoryImpl.getSessions', () {
    test('returns Right on success', () async {
      final now = DateTime.now();
      when(() => dataSource.getAll()).thenAnswer(
        (_) async => [
          SessionModel(
            id: 1,
            name: 'Push',
            description: '',
            createdAt: now,
            updatedAt: now,
            workoutCount: 0,
          ),
        ],
      );

      final result = await repository.getSessions();

      expect(result.isRight, isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (sessions) {
          expect(sessions, hasLength(1));
          expect(sessions.first.name, 'Push');
        },
      );
    });

    test('returns Left(DatabaseFailure) when datasource throws', () async {
      when(() => dataSource.getAll())
          .thenThrow(DatabaseException('boom', cause: 'sqlite'));

      final result = await repository.getSessions();

      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f, (_) => null), isA<DatabaseFailure>());
    });
  });

  group('SessionRepositoryImpl.deleteSession', () {
    test('returns Right(Unit) on success', () async {
      when(() => dataSource.delete(any())).thenAnswer((_) async {});
      when(() => dataSource.getAll()).thenAnswer((_) async => const []);

      final result = await repository.deleteSession(42);

      expect(result.isRight, isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (unit) => expect(unit, Unit.instance),
      );
      // The Firestore-only repository treats an empty list as
      // "already gone", so it returns success without calling delete
      // on the data source.
      verifyNever(() => dataSource.delete(any()));
    });

    test('forwards delete when session exists', () async {
      final now = DateTime.now();
      when(() => dataSource.getAll()).thenAnswer(
        (_) async => [
          SessionModel(
            id: 42,
            name: 'Push',
            description: '',
            createdAt: now,
            updatedAt: now,
            workoutCount: 0,
            firestoreId: 'abc',
          ),
        ],
      );
      when(() => dataSource.delete(any())).thenAnswer((_) async {});

      final result = await repository.deleteSession(42);

      expect(result.isRight, isTrue);
      verify(() => dataSource.delete('abc')).called(1);
    });
  });
}