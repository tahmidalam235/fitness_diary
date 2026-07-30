import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/session.dart';

/// State variants emitted by [SessionBloc].
sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => const [];
}

/// Initial state before any work has been done.
class SessionInitial extends SessionState {
  const SessionInitial();
}

/// Loading the list of sessions (first-load only; the stream itself
/// transitions directly to [SessionLoaded]).
class SessionLoading extends SessionState {
  const SessionLoading();
}

/// Successful state holding the current snapshot of sessions.
class SessionLoaded extends SessionState {
  const SessionLoaded({
    required this.sessions,
    this.isMutating = false,
    this.selectedSession,
  });

  final List<Session> sessions;
  final bool isMutating;
  final Session? selectedSession;

  SessionLoaded copyWith({
    List<Session>? sessions,
    bool? isMutating,
    Session? selectedSession,
    bool clearSelected = false,
  }) {
    return SessionLoaded(
      sessions: sessions ?? this.sessions,
      isMutating: isMutating ?? this.isMutating,
      selectedSession: clearSelected
          ? null
          : (selectedSession ?? this.selectedSession),
    );
  }

  @override
  List<Object?> get props => [sessions, isMutating, selectedSession];
}

/// A failure occurred while loading or mutating sessions.
class SessionError extends SessionState {
  const SessionError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}