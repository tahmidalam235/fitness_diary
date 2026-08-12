import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../domain/entities/session.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';
import '../widgets/session_form.dart';

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
  const SessionFormPage({this.sessionId, super.key});

  /// `null` for create mode; existing id for edit mode.
  final int? sessionId;

  bool get _isEditing => sessionId != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionBloc>(
      create: (_) {
        final bloc = getIt<SessionBloc>();
        if (_isEditing) {
          bloc.add(GetSessionByIdEvent(sessionId!));
        }
        return bloc;
      },
      child: _SessionFormView(sessionId: sessionId),
    );
  }
}

class _SessionFormView extends StatelessWidget {
  const _SessionFormView({required this.sessionId});

  final int? sessionId;

  bool get _isEditing => sessionId != null;

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
