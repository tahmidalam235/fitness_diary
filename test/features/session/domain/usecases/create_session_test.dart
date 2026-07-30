import 'package:fitness_diary/core/error/failure.dart';
import 'package:fitness_diary/core/utils/either.dart';
import 'package:fitness_diary/features/session/domain/entities/session.dart';
import 'package:fitness_diary/features/session/domain/repositories/session_repository.dart';
import 'package:fitness_diary/features/session/domain/usecases/create_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late _MockSessionRepository repository;
  late CreateSession useCase;

  setUp(() {
    repository = _MockSessionRepository();
    useCase = CreateSession(repository: repository);
  });

  group('CreateSession', () {
    test('returns ValidationFailure when name is empty', () async {
      final result = await useCase(
        const CreateSessionParams(name: '  '),
      );

      expect(result.isLeft, isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          final errors = (failure as ValidationFailure).errors;
          expect(errors.containsKey('name'), isTrue);
        },
        (_) => fail('expected Left'),
      );

      verifyNever(() => repository.createSession(
            name: any(named: 'name'),
            description: any(named: 'description'),
          ));
    });

    test('returns ValidationFailure when name is too long', () async {
      final result = await useCase(
        CreateSessionParams(
          name: 'x' * 61,
          description: '',
        ),
      );

      expect(result.isLeft, isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    });

    test('calls repository when name is valid', () async {
      final now = DateTime.now();
      final session = Session(
        id: 1,
        name: 'Push Day',
        description: '',
        createdAt: now,
        updatedAt: now,
      );

      when(() => repository.createSession(
            name: any(named: 'name'),
            description: any(named: 'description'),
          )).thenAnswer((_) async => Right(session));

      final result = await useCase(
        const CreateSessionParams(name: 'Push Day'),
      );

      expect(result.isRight, isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (returned) => expect(returned.id, 1),
      );

      verify(() => repository.createSession(
            name: 'Push Day',
            description: '',
          )).called(1);
    });
  });
}