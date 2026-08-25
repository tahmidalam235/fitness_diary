import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../domain/entities/session.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';
import '../widgets/session_form.dart';

/// Routes the new session to its details page after a successful create
/// instead of popping back. Activated by `afterCreate=details` query
/// param on `RouteNames.sessionNew`.
const String _kAfterCreateDetails = 'details';

/// Page for creating or editing a session.
///
/// When [sessionId] is `null`, the page is in create mode. Otherwise it
/// pre-loads the existing session via [GetSessionByIdEvent] and seeds
/// the form once the data arrives.
///
/// On submit, the form pops with a [SessionFormResult]; this page
/// dispatches the matching [CreateSessionEvent] / [UpdateSessionEvent]
/// to the [SessionBloc] so the change is persisted and the list is
/// refreshed automatically via Drift's reactive stream.
class SessionFormPage extends StatelessWidget {
  const SessionFormPage({this.sessionId, this.afterCreateAction, super.key});

  /// `null` for create mode; existing id for edit mode.
  final int? sessionId;

  /// `"details"` — in create mode, route to the new session's details
  /// page after save instead of popping back to the caller.
  final String? afterCreateAction;

  bool get _isEditing => sessionId != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionBloc>(
      create: (_) {
        final bloc = getIt<SessionBloc>();
        if (_isEditing) {
          bloc.add(GetSessionByIdEvent(sessionId!));
        } else {
          // Subscribe so the bloc surfaces the new session in
          // `state.sessions` after the create mutation completes.
          bloc.add(const WatchSessionsEvent());
        }
        return bloc;
      },
      child: _SessionFormView(
        sessionId: sessionId,
        afterCreateAction: afterCreateAction,
      ),
    );
  }
}

class _SessionFormView extends StatelessWidget {
  const _SessionFormView({
    required this.sessionId,
    required this.afterCreateAction,
  });

  final int? sessionId;
  final String? afterCreateAction;

  bool get _isEditing => sessionId != null;

  /// Awaits the create-mutation completion via the bloc's stream, then
  /// picks the newly added session out of `state.sessions` by diffing
  /// against the pre-submit list.
  ///
  /// Mirrors the `WorkoutFormPage` mutation-await pattern so the parent
  /// sees the updated state before we navigate. A 30s timeout guards
  /// against a hung repo pinning the listener subscription.
  Future<void> _createAndRouteToDetails(
    BuildContext context,
    SessionFormResult result,
  ) async {
    final bloc = context.read<SessionBloc>();
    // Capture the session list as it stands right now. Today page always
    // has the bloc loaded (the session picker only shows on
    // SessionLoaded), so this is the real "before" snapshot — diffing
    // against it is what guarantees we route to the session that was
    // just created, not one of the existing ones.
    final preSessions = bloc.state is SessionLoaded
        ? (bloc.state as SessionLoaded).sessions
        : const <Session>[];
    final preIds = {for (final s in preSessions) s.id};

    final completer = Completer<Session?>();
    late final StreamSubscription<SessionState> sub;
    void complete(Session? value) {
      if (completer.isCompleted) return;
      sub.cancel();
      completer.complete(value);
    }

    sub = bloc.stream.listen((state) {
      if (state is SessionLoaded &&
          state.sessions.length > preSessions.length) {
        complete(_findNew(state.sessions, preIds));
      } else if (state is SessionError) {
        complete(null);
      }
    });

    bloc.add(
      CreateSessionEvent(name: result.name, description: result.description),
    );
    final created = await completer.future
        // Safety net: a hung repo must not pin the listener subscription
        // for the lifetime of the (singleton) SessionBloc.
        .timeout(const Duration(seconds: 30), onTimeout: () {
      sub.cancel();
      return null;
    });

    if (!context.mounted || created == null || created.id == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session created successfully')),
    );
    context.pushReplacementNamed(
      RouteNames.sessionDetails,
      pathParameters: {'id': created.id.toString()},
      // Coming from the Today → "Add Session" picker, the user wants to
      // immediately pick workouts for today, so boot the details page
      // straight into select mode.
      queryParameters: {'select': '1'},
    );
  }

  /// Returns the first session in [latest] whose id wasn't present in
  /// [preIds]. Order matches insertion order, so the first hit is the
  /// session we just created.
  Session? _findNew(List<Session> latest, Set<int?> preIds) {
    for (final s in latest) {
      if (s.id != null && !preIds.contains(s.id)) return s;
    }
    return null;
  }

  Future<void> _onSubmit(BuildContext context, SessionFormResult result) async {
    final bloc = context.read<SessionBloc>();
    if (_isEditing) {
      bloc.add(
        UpdateSessionEvent(
          id: sessionId!,
          name: result.name,
          description: result.description,
        ),
      );
      // Wait for the bloc to finish writing so the parent details page
      // can re-fetch and see the new name without a race.
      await _awaitMutationFinished(bloc);
    } else if (afterCreateAction == _kAfterCreateDetails) {
      unawaited(_createAndRouteToDetails(context, result));
      return;
    } else {
      bloc.add(
        CreateSessionEvent(name: result.name, description: result.description),
      );
    }
    // Pop immediately — the bloc + Drift stream keeps the list in sync.
    if (context.mounted) {
      context.pop();
    }
  }

  /// Resolves when the bloc has finished its current mutation cycle
  /// (loaded + `!isMutating`) or hit an error. Mirrors the
  /// `WorkoutFormPage` await pattern so the parent screen sees the
  /// committed data when it re-fetches.
  Future<void> _awaitMutationFinished(SessionBloc bloc) async {
    final completer = Completer<void>();
    late final StreamSubscription<SessionState> sub;
    sub = bloc.stream.listen((state) {
      if (state is SessionLoaded && !state.isMutating) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete();
      } else if (state is SessionError) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });
    await completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _isEditing
        ? l10n.sessionFormTitleEdit
        : l10n.sessionFormTitleNew;

    return AppScaffold(
      title: title,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: BlocConsumer<SessionBloc, SessionState>(
          listenWhen: (prev, curr) =>
              prev is! SessionError && curr is SessionError,
          listener: (context, state) {
            if (state is SessionError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.failure.message)));
            }
          },
          builder: (context, state) {
            if (_isEditing) {
              final loaded = state is SessionLoaded
                  ? state.selectedSession
                  : null;
              if (loaded == null && state is! SessionError) {
                return const AppLoadingIndicator();
              }
              if (loaded != null) {
                return _buildForm(context, loaded);
              }
            }
            return _buildForm(context, null);
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, Session? initial) {
    return SessionForm(
      key: ValueKey(initial?.id ?? 'new'),
      initial: initial,
      onSubmit: (result) => _onSubmit(context, result),
    );
  }
}
