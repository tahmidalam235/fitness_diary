import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/responsive/screen_size.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../domain/entities/session.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';
import '../widgets/session_card.dart';

/// Lists all sessions and routes to create / edit / details flows.
///
/// Search is performed client-side over the bloc-provided list. New /
/// edited / deleted sessions arrive via [WatchSessionsEvent] and are
/// reflected immediately, so search results stay in sync without extra
/// plumbing.
class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionBloc>(
      create: (_) => getIt<SessionBloc>()..add(const WatchSessionsEvent()),
      child: const _SessionsView(),
    );
  }
}

class _SessionsView extends StatefulWidget {
  const _SessionsView();

  @override
  State<_SessionsView> createState() => _SessionsViewState();
}

class _SessionsViewState extends State<_SessionsView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Session> _applySearch(List<Session> source) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      return source;
    }
    return source
        .where((s) {
          return s.name.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.sessionsTitle,
      useNavigationRail: true,
      titleLeadingIcon: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.sessionNew),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.sessionsFabNew),
      ),
      body: BlocConsumer<SessionBloc, SessionState>(
        listenWhen: (prev, curr) =>
            curr is SessionError && prev is! SessionError,
        listener: (context, state) {
          if (state is SessionError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.failure.message)));
          }
        },
        builder: (context, state) {
          if (state is SessionLoading) {
            return const AppLoadingIndicator();
          }
          if (state is SessionError) {
            return AppErrorView(
              failure: state.failure,
              onRetry: () =>
                  context.read<SessionBloc>().add(const LoadSessionsEvent()),
            );
          }
          if (state is SessionLoaded) {
            return _buildLoaded(context, state, l10n);
          }
          return const Gap(0);
        },
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    SessionLoaded state,
    AppLocalizations l10n,
  ) {
    // No sessions at all -> Empty state with CTA.
    if (state.sessions.isEmpty) {
      return AppEmptyState(
        title: l10n.sessionsEmptyTitle,
        message: l10n.sessionsEmptyMessage,
        icon: Icons.fitness_center_rounded,
        actionLabel: l10n.sessionsEmptyAction,
        onAction: () => context.pushNamed(RouteNames.sessionNew),
      );
    }

    final filtered = _applySearch(state.sessions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: _SearchField(
            controller: _searchController,
            hint: l10n.sessionsSearchHint,
            clearLabel: l10n.sessionsSearchClear,
            hasQuery: _query.isNotEmpty,
            onChanged: (value) => setState(() => _query = value),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? AppEmptyState(
                  title: l10n.sessionsNoMatchesTitle(_query),
                  message: l10n.sessionsNoMatchesMessage,
                  icon: Icons.search_off_rounded,
                )
              : ResponsiveBuilder(
                  builder: (context, size) {
                    final crossAxisCount = switch (size) {
                      ScreenSize.compact => 1,
                      ScreenSize.medium => 2,
                      ScreenSize.expanded => 3,
                    };
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.xxxl,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: AppSpacing.lg,
                        crossAxisSpacing: AppSpacing.lg,
                        mainAxisExtent: 120,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final session = filtered[index];
                        return SessionCard(
                          session: session,
                          onTap: () => context.pushNamed(
                            RouteNames.sessionDetails,
                            pathParameters: {'id': session.id.toString()},
                          ),
                          onEdit: () => context.pushNamed(
                            RouteNames.sessionEdit,
                            pathParameters: {'id': session.id.toString()},
                          ),
                          onDelete: () => _confirmDelete(context, session.id!),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SessionBloc>();
    final state = bloc.state;
    final session = state is SessionLoaded
        ? state.sessions.where((s) => s.id == id).firstOrNull
        : null;
    final name = session?.name ?? '';

    final confirmed = await showConfirmDialog(
      context,
      title: l10n.sessionDeleteTitle,
      message: l10n.sessionDeleteMessage(name),
    );
    if (confirmed && context.mounted) {
      bloc.add(DeleteSessionEvent(id));
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.clearLabel,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final String clearLabel;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: hint,
        suffixIcon: hasQuery
            ? IconButton(
                tooltip: clearLabel,
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              )
            : null,
      ),
    );
  }
}
