import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/usecase/no_params.dart';
import '../../../../core/utils/either.dart';
import '../../../../features/history/domain/usecases/watch_frozen_days.dart';
import '../../../../features/history/domain/usecases/watch_logs_for_day.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../session/domain/entities/session.dart';
import '../../../session/presentation/bloc/session_bloc.dart';
import '../../../session/presentation/bloc/session_event.dart';
import '../../../session/presentation/bloc/session_state.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import 'package:fitness_diary/features/today/presentation/bloc/today_workouts_bloc.dart';

/// The Today page displays every workout session assigned for today.
/// Each session shows its configured workout details.
class TodayPage extends StatefulWidget {
  const TodayPage({this.initialSessionId, super.key});

  final int? initialSessionId;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  bool _isTodayFrozen = false;
  List<WorkoutLog> _todayLogs = [];
  bool _isPickingSession = false;

  StreamSubscription<Either<Failure, List<WorkoutLog>>>? _logsSub;
  StreamSubscription<Either<Failure, Set<DateTime>>>? _frozenSub;

  @override
  void initState() {
    super.initState();
    _subscribeToLogs();
    _watchFrozen();
  }

  @override
  void dispose() {
    _logsSub?.cancel();
    _frozenSub?.cancel();
    super.dispose();
  }

  void _subscribeToLogs() {
    _logsSub = getIt<WatchLogsForDay>()(DateTime.now()).listen((result) {
      if (!mounted) return;
      result.fold((_) {}, (logs) {
        setState(() {
          _todayLogs = logs;
        });
      });
    });
  }

  void _watchFrozen() {
    _frozenSub = getIt<WatchFrozenDays>()(const NoParams()).listen((result) {
      if (!mounted) return;
      result.fold((_) {}, (frozen) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final frozenToday = frozen.contains(today);
        if (frozenToday != _isTodayFrozen) {
          setState(() {
            _isTodayFrozen = frozenToday;
          });
        }
      });
    });
  }

  void _onAddMoreSession(int sessionId) {
    setState(() => _isPickingSession = false);
    // Fix 4: Navigate to session details with workout selection mode enabled.
    context.pushNamed(
      RouteNames.sessionDetails,
      pathParameters: {'id': sessionId.toString()},
      queryParameters: {'select': '1'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dayName = DateFormat('EEEE').format(DateTime.now());

    return BlocProvider<SessionBloc>(
      create: (_) => getIt<SessionBloc>()..add(const WatchSessionsEvent()),
      child: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, state) {
          if (_isPickingSession && state is SessionLoaded) {
            return AppScaffold(
              title: 'Add Session',
              showBackButton: true,
              body: _SessionPicker(
                sessions: state.sessions,
                pickedId: null,
                onPick: _onAddMoreSession,
                onClear: () => setState(() => _isPickingSession = false),
              ),
            );
          }

          return AppScaffold(
            title: l10n.navToday,
            useNavigationRail: true,
            titleLeadingIcon: true,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isTodayFrozen) const _FrozenBanner(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Text(
                          dayName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const Divider(
                        indent: AppSpacing.lg,
                        endIndent: AppSpacing.lg,
                      ),
                      if (_todayLogs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'No sessions assigned for today.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        for (final log in _todayLogs)
                          // Fix 2 & 3: Use log.id as key to preserve Bloc state and
                          // filter out sessions that no longer exist.
                          _SessionSection(
                            key: ValueKey(log.id),
                            log: log,
                            allSessions: state is SessionLoaded
                                ? state.sessions
                                : const [],
                          ),
                      const Gap(AppSpacing.xl),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _isPickingSession = true),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            _todayLogs.isEmpty
                                ? 'Add Workout for Today'
                                : 'Add More Session for Today',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SessionSection extends StatelessWidget {
  const _SessionSection({
    super.key,
    required this.log,
    required this.allSessions,
  });

  final WorkoutLog log;
  final List<Session> allSessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = allSessions.where((s) => s.id == log.sessionId).firstOrNull;

    // Fix 2: If the session template was deleted, don't show the orphaned log.
    if (session == null) return const SizedBox.shrink();

    return BlocProvider<TodayWorkoutsBloc>(
      create: (_) =>
          getIt<TodayWorkoutsBloc>()
            ..add(WatchTodayWorkoutsEvent(log.sessionId)),
      child: BlocBuilder<TodayWorkoutsBloc, TodayWorkoutsState>(
        builder: (context, state) {
          // Fix 1: If there are no entries for this session today, hide it.
          // This happens when the user deletes the last workout record.
          if (state is TodayWorkoutsLoaded && state.entries.isEmpty) {
            return const SizedBox.shrink();
          }

          if (state is TodayWorkoutsLoading || state is TodayWorkoutsInitial) {
            return const AppLoadingIndicator();
          }

          if (state is TodayWorkoutsLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    session.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                _TodayWorkoutsList(
                  workoutsById: state.workoutsById,
                  entries: state.entries,
                  sessionId: log.sessionId,
                ),
                const Gap(AppSpacing.md),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TodayWorkoutsList extends StatelessWidget {
  const _TodayWorkoutsList({
    required this.workoutsById,
    required this.entries,
    required this.sessionId,
  });

  final Map<int, Workout> workoutsById;
  final List<WorkoutLogEntry> entries;
  final int sessionId;

  @override
  Widget build(BuildContext context) {
    final entryMap = {for (final e in entries) e.workoutId: e};

    // Fix 1: Filter to only show workouts that actually have a record for today.
    final workoutsToShow =
        workoutsById.values
            .where((w) => entryMap.containsKey(w.workoutId))
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: workoutsToShow.length,
      itemBuilder: (context, index) {
        final workout = workoutsToShow[index];
        final entry = entryMap[workout.workoutId];

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
    this.entry,
    required this.sessionId,
  });

  final Workout workout;
  final WorkoutLogEntry? entry;
  final int sessionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use entry values (today's progress) if they exist,
    // otherwise fallback to template defaults.
    final sets = entry?.sets ?? workout.defaultSets;
    final reps = entry?.reps ?? workout.defaultReps;
    final weight = entry?.weight ?? workout.defaultWeight;
    final duration = entry?.durationSeconds ?? workout.defaultDurationSeconds;
    final notes = (entry?.notes.isNotEmpty ?? false)
        ? entry!.notes
        : workout.notes;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.pushNamed(
          RouteNames.workoutTracking,
          pathParameters: {
            'id': sessionId.toString(),
            'workoutId': workout.id.toString(),
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    entry != null ? Icons.check_circle_rounded : Icons.circle,
                    size: 8,
                    color: entry != null
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: Text(
                      workout.exerciseName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: entry != null ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ),
                  if (entry != null)
                    Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  _WorkoutDetailItem(label: 'Sets', value: '$sets'),
                  _WorkoutDetailItem(label: 'Reps', value: '$reps'),
                  if (weight != null)
                    _WorkoutDetailItem(
                      label: 'Weight',
                      value:
                          '${weight == weight.toInt() ? weight.toInt() : weight} kg',
                    ),
                  if (duration != null)
                    _WorkoutDetailItem(
                      label: 'Duration',
                      value: '${duration}s',
                    ),
                ],
              ),
              if (notes.isNotEmpty) ...[
                const Gap(AppSpacing.sm),
                Text(
                  notes,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutDetailItem extends StatelessWidget {
  const _WorkoutDetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FrozenBanner extends StatelessWidget {
  const _FrozenBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Icon(Icons.ac_unit_rounded, size: 20, color: Color(0xFF60A5FA)),
          const Gap(AppSpacing.md),
          Expanded(
            child: Text(
              'TODAY IS FROZEN. Your streak is protected even if you don\'t workout today.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.pushNamed(RouteNames.freeze),
            child: const Text('MANAGE'),
          ),
        ],
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
            itemBuilder: (context, index) {
              final s = sessions[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      s.name.isEmpty ? '?' : s.name[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    s.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: s.description.isEmpty
                      ? null
                      : Text(
                          s.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: const Icon(Icons.add_rounded),
                  onTap: () => onPick(s.id!),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
