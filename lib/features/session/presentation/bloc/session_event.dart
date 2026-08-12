import 'package:equatable/equatable.dart';

import '../../domain/entities/session.dart';

/// Base class for all events handled by [SessionBloc].
sealed class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => const [];
}

/// Subscribes to the sessions table for live updates.
class WatchSessionsEvent extends SessionEvent {
  const WatchSessionsEvent();
}

/// Internal event used by the bloc to push the latest snapshot into the
/// stream subscription.
class SessionsReceived extends SessionEvent {
  const SessionsReceived(this.sessions);

  final List<Session> sessions;

  @override
  List<Object?> get props => [sessions];
}

/// Loads all sessions once.
class LoadSessionsEvent extends SessionEvent {
  const LoadSessionsEvent();
}

/// Loads a single session by id (used by details / edit forms).
class GetSessionByIdEvent extends SessionEvent {
  const GetSessionByIdEvent(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Internal event for pushing a single-session result into the bloc.
class SessionReceived extends SessionEvent {
  const SessionReceived(this.session);

  final Session session;

  @override
  List<Object?> get props => [session];
}

/// Creates a new session.
class CreateSessionEvent extends SessionEvent {
  const CreateSessionEvent({required this.name, this.description = ''});

  final String name;
  final String description;

  @override
  List<Object?> get props => [name, description];
}

/// Updates an existing session.
class UpdateSessionEvent extends SessionEvent {
  const UpdateSessionEvent({
    required this.id,
    required this.name,
    this.description = '',
  });

  final int id;
  final String name;
  final String description;

  @override
  List<Object?> get props => [id, name, description];
}

/// Deletes a session by id.
class DeleteSessionEvent extends SessionEvent {
  const DeleteSessionEvent(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// Internal event indicating a mutation has started; used to flip the
/// `isMutating` flag on the state so the UI can show spinners.
class MutationStarted extends SessionEvent {
  const MutationStarted();
}

/// Internal event indicating a mutation completed (success or failure).
class MutationFinished extends SessionEvent {
  const MutationFinished();
}
