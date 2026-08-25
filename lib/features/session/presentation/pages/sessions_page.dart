import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/responsive/screen_size.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_workout_card.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../domain/entities/session.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';

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
      floatingActionButton: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, state) {
          // The empty state in the body already surfaces the "CREATE
          // SESSION" CTA, so suppress the FAB while there are no
          // sessions to avoid a duplicate.
          if (state is SessionLoaded && state.sessions.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => context.pushNamed(RouteNames.sessionNew),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.sessionsFabNew.toUpperCase()),
          );
        },
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
    final totalWorkouts = state.sessions.fold<int>(
      0,
      (sum, s) => sum + s.workoutCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SessionsHero(
          sessionCount: state.sessions.length,
          workoutCount: totalWorkouts,
        ),
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
                        mainAxisExtent: 130,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final session = filtered[index];
                        return _SessionGridCard(
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

/// Compact hero header for the Sessions list — session count, total
/// workout count and a brand-aligned gradient banner.
class _SessionsHero extends StatelessWidget {
  const _SessionsHero({
    required this.sessionCount,
    required this.workoutCount,
  });

  final int sessionCount;
  final int workoutCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.style_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SESSIONS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your training library',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _MiniPill(label: '$sessionCount SESSIONS'),
                      const SizedBox(width: AppSpacing.xs),
                      _MiniPill(label: '$workoutCount WORKOUTS'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// A more compact, grid-friendly session card (used in the Sessions
/// list grid). Uses [AppSessionCard] semantics but is wrapped in an
/// InkWell so it fills the grid cell cleanly.
class _SessionGridCard extends StatelessWidget {
  const _SessionGridCard({
    required this.session,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Session session;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppSessionCard(
      title: session.name,
      description: session.description.isEmpty ? null : session.description,
      workoutCount: session.workoutCount,
      onTap: onTap,
      trailing: PopupMenuButton<_SessionAction>(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.more_vert_rounded, size: 18),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        onSelected: (action) {
          switch (action) {
            case _SessionAction.edit:
              onEdit();
              break;
            case _SessionAction.delete:
              onDelete();
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _SessionAction.edit,
            child: Row(
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Edit',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: _SessionAction.delete,
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _SessionAction { edit, delete }

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
