import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../session/domain/entities/session.dart';
import '../../../session/presentation/bloc/session_bloc.dart';
import '../../../session/presentation/bloc/session_event.dart';
import '../../../session/presentation/bloc/session_state.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import '../bloc/today_workouts_bloc.dart';

/// The Today page.
///
/// Flow:
///   - When no session is picked yet, show a "Pick a session" prompt
///     (or "create your first session" if no sessions exist at all).
///   - When a session is picked, watch the workouts attached to it and
///     present them as a clean list. Tapping a workout drills into the
///     per-workout tracking screen (Feature 3).
///   - "Change session" clears the picked session so the user can pick
///     another one.
class TodayPage extends StatefulWidget {
  const TodayPage({this.initialSessionId, super.key});

  /// Optional session id that should be picked automatically when the
  /// page first loads. Used by the Session Details "Add for Today's
  /// Session" action, which navigates to Today after writing rows so
  /// the user lands directly on the just-populated list instead of the
  /// session picker.
  final int? initialSessionId;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  int? _pickedSessionId;

  @override
  void initState() {
    super.initState();
    _pickedSessionId = widget.initialSessionId;
  }

  /// Persists the user's session choice across rebuilds. Once a session is
  /// picked it stays selected until the user explicitly changes it (via
  /// the "Change session" action) or the session itself is deleted.
  void _pickSession(int id) {
    setState(() => _pickedSessionId = id);
  }

  void _clearPickedSession() {
    setState(() => _pickedSessionId = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider<SessionBloc>(
      create: (_) => getIt<SessionBloc>()
        ..add(const WatchSessionsEvent()),
      child: AppScaffold(
        title: l10n.navToday,
        useNavigationRail: true,
        body: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) {
            if (state is SessionLoading) {
              return const AppLoadingIndicator();
            }
            if (state is SessionError) {
              return AppEmptyState(
                title: l10n.commonErrorTitle,
                message: state.failure.message,
                icon: Icons.error_outline_rounded,
              );
            }
            if (state is SessionLoaded) {
              return _buildLoaded(context, state, l10n);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    SessionLoaded state,
    AppLocalizations l10n,
  ) {
    // No sessions at all.
    if (state.sessions.isEmpty) {
      return AppEmptyState(
        title: l10n.todayEmptyTitle,
        message: l10n.sessionsEmptyMessage,
        icon: Icons.fitness_center_rounded,
        actionLabel: l10n.sessionsEmptyAction,
        onAction: () => context.pushNamed(RouteNames.sessionNew),
      );
    }

    // Picked session gone (deleted)? Reset.
    Session? picked;
    if (_pickedSessionId != null) {
      for (final s in state.sessions) {
        if (s.id == _pickedSessionId) {
          picked = s;
          break;
        }
      }
      if (picked == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _clearPickedSession();
        });
      }
    }

    if (picked == null) {
      return _SessionPicker(
        sessions: state.sessions,
        pickedId: _pickedSessionId,
        onPick: _pickSession,
        onClear: _clearPickedSession,
      );
    }

    final pickedId = picked.id!;
    // Session picked: stream today's log entries for it and render each
    // as a single tracking card. The user picks which workouts to
    // include from the Session details page.
    return BlocProvider<TodayWorkoutsBloc>(
      create: (_) => getIt<TodayWorkoutsBloc>()
        ..add(WatchTodayWorkoutsEvent(pickedId)),
      child: _PickedSessionView(
        sessionName: picked.name,
        sessionId: pickedId,
        onChange: _clearPickedSession,
      ),
    );
  }
}

class _SessionPicker extends StatelessWidget {
  const _SessionPicker({
    required this.sessions,
    required this.pickedId,
    required this.onPick,
    required this.onClear,
  });

  final List<Session> sessions;
  final int? pickedId;
  final ValueChanged<int> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.todayEmptyTitle, style: theme.textTheme.headlineSmall),
              const Gap(AppSpacing.xs),
              Text(
                l10n.todayEmptyMessage,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
            itemBuilder: (context, index) {
              final s = sessions[index];
              final isPicked = s.id == pickedId;
              return Card(
                clipBehavior: Clip.antiAlias,
                color: isPicked
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(
                    color: isPicked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: isPicked ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  selected: isPicked,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isPicked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primaryContainer,
                    child: Text(
                      s.name.isEmpty ? '?' : s.name[0].toUpperCase(),
                      style: TextStyle(
                        color: isPicked
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    s.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isPicked
                          ? theme.colorScheme.onPrimaryContainer
                          : null,
                      fontWeight:
                          isPicked ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  subtitle: s.description.isEmpty
                      ? null
                      : Text(
                          s.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isPicked
                                ? theme.colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.8)
                                : null,
                          ),
                        ),
                  trailing: isPicked
                      ? _SelectedBadge(
                          label: l10n.todaySelectedLabel,
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  onTap: () => onPick(s.id!),
                ),
              );
            },
          ),
        ),
        if (pickedId != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: FilledButton.tonalIcon(
              onPressed: onClear,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(l10n.todayEmptyAction),
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: theme.colorScheme.onPrimary,
          ),
          const Gap(AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickedSessionView extends StatelessWidget {
  const _PickedSessionView({
    required this.sessionName,
    required this.sessionId,
    required this.onChange,
  });

  final String sessionName;
  final int sessionId;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessionName,
                      style: theme.textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const Gap(AppSpacing.xxs),
                    Text(
                      l10n.todayEmptyAction,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onChange,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(l10n.todayEmptyAction),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<TodayWorkoutsBloc, TodayWorkoutsState>(
            builder: (context, state) {
              if (state is TodayWorkoutsLoading ||
                  state is TodayWorkoutsInitial) {
                return const AppLoadingIndicator();
              }
              if (state is TodayWorkoutsError) {
                return AppEmptyState(
                  title: l10n.commonErrorTitle,
                  message: state.failure.message,
                  icon: Icons.error_outline_rounded,
                );
              }
              if (state is TodayWorkoutsLoaded) {
                if (state.entries.isEmpty) {
                  return AppEmptyState(
                    title: 'No workouts started yet',
                    message:
                        'Pick the exercises you want to do today from "$sessionName".',
                    icon: Icons.fitness_center_rounded,
                    actionLabel: 'Pick workouts for today',
                    onAction: () => context.pushNamed(
                      RouteNames.sessionDetails,
                      pathParameters: {'id': sessionId.toString()},
                      queryParameters: {'select': '1'},
                    ),
                  );
                }
                return _TodayWorkoutsList(
                  entries: state.entries,
                  workoutsById: state.workoutsById,
                  sessionId: sessionId,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _TodayWorkoutsList extends StatelessWidget {
  const _TodayWorkoutsList({
    required this.entries,
    required this.workoutsById,
    required this.sessionId,
  });

  final List<WorkoutLogEntry> entries;
  final Map<int, Workout> workoutsById;
  final int sessionId;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final workout = workoutsById[entry.workoutId];
        if (workout == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _TodayWorkoutCard(
            workout: workout,
            entry: entry,
            sessionId: sessionId,
          ),
        );
      },
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard({
    required this.workout,
    required this.entry,
    required this.sessionId,
  });

  final Workout workout;
  final WorkoutLogEntry entry;
  final int sessionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.workoutTracking,
          pathParameters: {
            'id': sessionId.toString(),
            'workoutId': workout.workoutId.toString(),
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: Text(
                      workout.exerciseName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded, size: 18),
                ],
              ),
              const Gap(AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _TodayValue(label: 'Sets', value: entry.sets?.toString() ?? '—'),
                  _TodayValue(label: 'Reps', value: entry.reps?.toString() ?? '—'),
                  _TodayValue(
                    label: 'Weight',
                    value: entry.weight == null ? '—' : '${entry.weight} kg',
                  ),
                  _TodayValue(
                    label: 'Duration',
                    value: entry.durationSeconds == null
                        ? '—'
                        : '${(entry.durationSeconds! / 60).round()}m',
                  ),
                ],
              ),
              const Gap(AppSpacing.xs),
              Text(
                'Tap to edit today\'s record',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayValue extends StatelessWidget {
  const _TodayValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
