import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_diary/core/error/failure.dart';
import 'package:fitness_diary/core/usecase/no_params.dart';
import 'package:fitness_diary/core/utils/either.dart';
import 'package:fitness_diary/features/session/domain/entities/session.dart';
import 'package:fitness_diary/features/session/domain/repositories/session_repository.dart';
import 'package:fitness_diary/features/session/domain/usecases/create_session.dart';
import 'package:fitness_diary/features/session/domain/usecases/delete_session.dart';
import 'package:fitness_diary/features/session/domain/usecases/get_session_by_id.dart';
import 'package:fitness_diary/features/session/domain/usecases/get_sessions.dart';
import 'package:fitness_diary/features/session/domain/usecases/update_session.dart';
import 'package:fitness_diary/features/session/domain/usecases/watch_sessions.dart';
import 'package:fitness_diary/features/session/presentation/bloc/session_bloc.dart';
import 'package:fitness_diary/features/session/presentation/bloc/session_event.dart';
import 'package:fitness_diary/features/session/presentation/bloc/session_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

class _FakeCreateSessionParams extends Fake implements CreateSessionParams {}

class _FakeUpdateSessionParams extends Fake implements UpdateSessionParams {}

void main() {
  late SessionBloc bloc;
  late _MockSessionRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeCreateSessionParams());
    registerFallbackValue(_FakeUpdateSessionParams());
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    repository = _MockSessionRepository();
    bloc = SessionBloc(
      getSessions: GetSessions(repository: repository),
      watchSessions: WatchSessions(repository: repository),
      getSessionById: GetSessionById(repository: repository),
      createSession: CreateSession(repository: repository),
      updateSession: UpdateSession(repository: repository),
      deleteSession: DeleteSession(repository: repository),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  group('SessionBloc.LoadSessionsEvent', () {
    blocTest<SessionBloc, SessionState>(
      'emits [Loading, Loaded] on success',
      setUp: () {
        when(() => repository.getSessions()).thenAnswer(
          (_) async => const Right(<Session>[]),
        );
      },
      build: () => bloc,
      act: (b) => b.add(const LoadSessionsEvent()),
      expect: () => [
        const SessionLoading(),
        const SessionLoaded(sessions: <Session>[]),
      ],
      verify: (_) {
        verify(() => repository.getSessions()).called(1);
      },
    );

    blocTest<SessionBloc, SessionState>(
      'emits [Loading, Error] on failure',
      setUp: () {
        when(() => repository.getSessions()).thenAnswer(
          (_) async => const Left(DatabaseFailure(message: 'boom')),
        );
      },
      build: () => bloc,
      act: (b) => b.add(const LoadSessionsEvent()),
      expect: () => [
        const SessionLoading(),
        const SessionError(DatabaseFailure(message: 'boom')),
      ],
    );
  });
}