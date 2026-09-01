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
import '../../../../core/theme/app_theme.dart';
import '../../../../core/usecase/no_params.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../features/history/domain/usecases/watch_frozen_days.dart';
import '../../../../features/workout_log/data/models/workout_log_model.dart';
import '../../../../features/history/domain/usecases/watch_logs_for_day.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_workout_card.dart';
import '../../../session/domain/entities/session.dart';
import '../../../session/presentation/bloc/session_bloc.dart';
import '../../../session/presentation/bloc/session_event.dart';
import '../../../session/presentation/bloc/session_state.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import '../bloc/today_workouts_bloc.dart';

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

  /// All workout days (date-only) used for streak calculation.
  Set<DateTime> _allWorkoutDays = const <DateTime>{};

  /// All frozen days (date-only) used for streak calculation.
  Set<DateTime> _frozenDays = const <DateTime>{};

  StreamSubscription<Either<Failure, List<WorkoutLog>>>? _logsSub;
  StreamSubscription<Either<Failure, Set<DateTime>>>? _frozenSub;
  StreamSubscription<List<WorkoutLogModel>>? _allLogsSub;

  /// Consecutive days ending today (or yesterday if today not yet
  /// worked out). A frozen day counts as a passing day so intentional
  /// rest days don't reset the streak. Returns 0 if there's no recent
  /// activity on either side.
  ///
  /// Mirrors the algorithm used in `StreakPage` and the drawer's
  /// progress badge so the number surfaced on the Today card stays
  /// consistent with those surfaces.
  static int _computeStreak(
    Set<DateTime> workoutDays,
    Set<DateTime> frozenDays,
    DateTime now,
  ) {
    final passing = <DateTime>{...workoutDays, ...frozenDays};
    if (passing.isEmpty) return 0;
    final today = DateTime(now.year, now.month, now.day);
    DateTime cursor = today;
    int streak = 0;
    // If today isn't a passing day, start counting from yesterday so
    // the streak doesn't visually reset before the day ends.
    if (!passing.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!passing.contains(cursor)) return 0;
    }
    while (passing.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  void initState() {
    super.initState();
    _subscribeToLogs();
    _watchFrozen();
    _subscribeToAllLogs();
  }

  @override
  void dispose() {
    _logsSub?.cancel();
    _frozenSub?.cancel();
    _allLogsSub?.cancel();
    super.dispose();
  }

  void _subscribeToLogs() {
    // Drop any prior subscription so a back-to-back re-subscribe
    // (e.g. after a fresh restore) doesn't double-fire.
    _logsSub?.cancel();
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
    _frozenSub?.cancel();
    _frozenSub = getIt<WatchFrozenDays>()(const NoParams()).listen((result) {
      if (!mounted) return;
      result.fold((_) {}, (frozen) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final frozenToday = frozen.contains(today);
        if (frozenToday != _isTodayFrozen) {
          setState(() {
            _isTodayFrozen = frozenToday;
            _frozenDays = frozen;
          });
        } else if (frozen.length != _frozenDays.length) {
          // Streak counter depends on the full frozen set, so refresh
          // when membership changes even if "today" status is stable.
          setState(() {
            _frozenDays = frozen;
          });
        }
      });
    });
  }

  /// Streams every workout log in the user's history. Used only for
  /// the streak counter — the today-only stream above drives the rest
  /// of the page.
  void _subscribeToAllLogs() {
    _allLogsSub?.cancel();
    _allLogsSub = getIt<WorkoutLogDao>().watchAllLogs().listen((logs) {
      if (!mounted) return;
      final days = <DateTime>{
        for (final log in logs)
          DateTime(
            log.performedAt.year,
            log.performedAt.month,
            log.performedAt.day,
          ),
      };
      setState(() {
        _allWorkoutDays = days;
      });
    });
  }

  void _onAddMoreSession(int sessionId) {
    // Keep `_isPickingSession` true while the session-details page sits
    // on top so the navigator stack behaves symmetrically: picking a
    // session pushes session-details, backing out returns to the picker,
    // and backing out again returns to the plain Today view. Flipping
    // the flag here used to skip the picker on the way back.
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
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final dateLabel = DateFormat('MMMM d').format(now);

    return BlocProvider<SessionBloc>(
      create: (_) {
        final bloc = getIt<SessionBloc>()..add(const WatchSessionsEvent());
        return bloc;
      },
      child: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, state) {
          if (_isPickingSession && state is SessionLoaded) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                setState(() => _isPickingSession = false);
              },
              child: AppScaffold(
                title: 'Add Session',
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() => _isPickingSession = false),
                ),
                body: _SessionPicker(
                  sessions: state.sessions,
                  pickedId: null,
                  onPick: _onAddMoreSession,
                  onClear: () => setState(() => _isPickingSession = false),
                ),
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
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: _TodayHero(
                          dayName: dayName,
                          dateLabel: dateLabel,
                          sessionCount: _todayLogs.length,
                          gradient: AppTheme.heroGradient,
                          streakDays: _computeStreak(
                            _allWorkoutDays,
                            _frozenDays,
                            now,
                          ),
                          workedOutToday: _todayLogs.isNotEmpty,
                        ),
                      ),
                      if (_todayLogs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.xl,
                            AppSpacing.lg,
                            AppSpacing.xl,
                          ),
                          child: AppEmptyState(
                            title: l10n.todayEmptyTitle,
                            message: l10n.todayEmptyMessage,
                            icon: Icons.play_circle_outline_rounded,
                            actionLabel: 'SELECT SESSION',
                            onAction: () =>
                                setState(() => _isPickingSession = true),
                          ),
                        )
                      else
                        // Filter out logs whose underlying session no
                        // longer exists — these used to render as a
                        // placeholder "Workout" header each, which was
                        // confusing once a session was renamed or
                        // deleted. We only keep logs we can join back
                        // to a current session.
                        Builder(
                          builder: (context) {
                            // Only filter once the SessionBloc has
                            // actually loaded — otherwise we'd hide
                            // every section during the initial render.
                            final sessionsLoaded = state is SessionLoaded;
                            final sessions = sessionsLoaded
                                ? state.sessions
                                : const <Session>[];
                            final logsForSessions = sessionsLoaded
                                ? _todayLogs
                                      .where(
                                        (log) => sessions.any(
                                          (s) => s.id == log.sessionId,
                                        ),
                                      )
                                      .toList(growable: false)
                                : _todayLogs;
                            if (logsForSessions.isEmpty) {
                              // No joinable logs yet — surface the empty
                              // state CTA rather than blank sections.
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  AppSpacing.xl,
                                  AppSpacing.lg,
                                  AppSpacing.xl,
                                ),
                                child: AppEmptyState(
                                  title: l10n.todayEmptyTitle,
                                  message: l10n.todayEmptyMessage,
                                  icon: Icons.play_circle_outline_rounded,
                                  actionLabel: 'SELECT SESSION',
                                  onAction: () => setState(
                                    () => _isPickingSession = true,
                                  ),
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final log in logsForSessions)
                                  _SessionSection(
                                    key: ValueKey(log.id),
                                    log: log,
                                    allSessions: sessions,
                                  ),
                                const Gap(AppSpacing.md),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                  ),
                                  child: OutlinedButton.icon(
                                    onPressed: () => setState(
                                      () => _isPickingSession = true,
                                    ),
                                    icon: const Icon(Icons.add_rounded),
                                    label: Text(
                                      (state is SessionLoaded &&
                                              state.sessions.isEmpty)
                                          ? 'Add Session for Today'
                                          : 'Add More Session for Today',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.md,
                                      ),
                                      side: BorderSide(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.5),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
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

/// Big hero header for the Today page: weekday + date + session count
/// chip rendered inside the hero gradient.
class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.dayName,
    required this.dateLabel,
    required this.sessionCount,
    required this.gradient,
    required this.streakDays,
    required this.workedOutToday,
  });

  final String dayName;
  final String dateLabel;
  final int sessionCount;
  final Gradient gradient;

  /// Current consecutive-day workout streak. Zero when the user has no
  /// recent activity. The Today card shows nothing in that case.
  final int streakDays;

  /// True when the user has completed at least one workout today. When
  /// false but [streakDays] is positive, the card displays a
  /// "keep it going" message instead of "current streak".
  final bool workedOutToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  'TODAY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (streakDays > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Current Streak: $streakDays ${_pluralDays(streakDays)}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (streakDays > 0 && !workedOutToday)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Turn it into ${streakDays + 1} today!',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  if (streakDays > 0 && sessionCount > 0)
                    const SizedBox(height: AppSpacing.xs),
                  if (sessionCount > 0)
                    _WhitePill(
                      icon: Icons.bolt_rounded,
                      iconColor: theme.colorScheme.primary,
                      text:
                          '$sessionCount session${sessionCount == 1 ? '' : 's'}',
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            dayName,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// White pill with leading icon + text, used inside the Today hero for
/// the streak and session-count chips. Both share the same shape and
/// typography so this widget exists once and is reused.
class _WhitePill extends StatelessWidget {
  const _WhitePill({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

String _pluralDays(int n) => 'Day${n == 1 ? '' : 's'}';

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

    // Fallback title when the session template hasn't loaded yet (e.g.
    // right after a fresh login while the SessionBloc is still warming
    // up). Showing a placeholder keeps the section visible so the
    // workout cards underneath are never silently hidden by an empty
    // SizedBox; the real name replaces this on the next frame.
    final title = session?.name ?? 'Today';

    // Fix 5: each session's TodayWorkoutsBloc is provided HERE (inside
    // _SessionSection), not in a MultiBlocProvider above the section
    // list. Putting them all in one MultiBlocProvider nested the
    // providers in declaration order, so BlocBuilder lookup found the
    // innermost (last) provider for every section — every section then
    // rendered with that one bloc's data, mixing entries across
    // sessions. A per-section BlocProvider makes the lookup
    // unambiguous.
    return BlocProvider<TodayWorkoutsBloc>(
      key: ValueKey('tw-${log.id}'),
      create: (_) => getIt<TodayWorkoutsBloc>()
        ..add(WatchTodayWorkoutsEvent(log.sessionId)),
      child: BlocBuilder<TodayWorkoutsBloc, TodayWorkoutsState>(
        builder: (context, state) {
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
                  child: AppSectionHeader(
                    title: title,
                    icon: Icons.fitness_center_rounded,
                    accent: session == null
                        ? theme.colorScheme.outline
                        : theme.colorScheme.primary,
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

          if (state is TodayWorkoutsLoading ||
              state is TodayWorkoutsInitial) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: AppLoadingIndicator(),
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

    // Fix 1: Filter to only show workouts that have a record for
    // today AND still exist in the session's workout list. Orphan
    // entries (workout deleted from the session but the entry
    // remained) used to slip through here and lead to "Workout not
    // found" on click. By also requiring `workoutFirestoreId` to
    // match a current workout, those rows are filtered out as well.
    final workoutsToShow =
        workoutsById.values
            .where((w) => entryMap.containsKey(w.workoutId))
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

    // Use a Column instead of a nested ListView.builder. Nested
    // ListViews with `shrinkWrap + NeverScrollableScrollPhysics` inside
    // another scrolling ListView cause layout errors ("RenderBox was
    // not laid out", "BoxConstraints forces an infinite width") and
    // scroll stutter. A Column of Padding-wrapped cards is the
    // correct, stable shape here.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final workout in workoutsToShow)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppWorkoutCard(
                workout: workout,
                entry: entryMap[workout.workoutId],
                position: workout.position,
                completed: entryMap[workout.workoutId] != null,
                onTap: () => context.pushNamed(
                  RouteNames.workoutTracking,
                  pathParameters: {
                    'id': sessionId.toString(),
                    'workoutId': workout.id.toString(),
                  },
                ),
              ),
            ),
        ],
      ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.frostBlue.withValues(alpha: 0.18),
            AppTheme.accentIce.withValues(alpha: 0.12),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.frostBlue.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.frostBlue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.ac_unit_rounded,
              size: 18,
              color: AppTheme.frostBlue,
            ),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Text(
              "TODAY IS FROZEN. Your streak is protected even if you don't workout today.",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.4,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.pushNamed(RouteNames.freeze),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
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
    final l10n = AppLocalizations.of(context);

    if (sessions.isEmpty) {
      return AppEmptyState(
        title: l10n.sessionsEmptyTitle,
        message: l10n.sessionsEmptyMessage,
        icon: Icons.fitness_center_rounded,
        actionLabel: l10n.sessionsEmptyAction,
        onAction: () {
          onClear(); // This will set _isPickingSession to false in TodayPage
          context.pushNamed(
            RouteNames.sessionNew,
            queryParameters: {'afterCreate': 'details'},
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in sessions) ...[
            AppSessionCard(
              title: s.name,
              description: s.description.isEmpty ? null : s.description,
              workoutCount: s.workoutCount,
              onTap: () => onPick(s.id!),
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {
              onClear();
              context.pushNamed(
                RouteNames.sessionNew,
                queryParameters: {'afterCreate': 'details'},
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.sessionsFabNew),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
