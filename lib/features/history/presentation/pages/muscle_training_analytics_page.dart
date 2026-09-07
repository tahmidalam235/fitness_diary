import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../workout/domain/entities/body_part.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import '../../domain/usecases/get_workouts_by_ids.dart';
import '../../domain/usecases/watch_entries_in_range.dart';
import '../../domain/usecases/watch_logs_in_range.dart';

/// View modes supported by [MuscleTrainingAnalyticsPage].
enum _AnalyticsPeriod { week, month }

/// Full-screen "Muscle Training Analytics" page.
///
/// Counts only actual completed entries (rows in `WorkoutLogEntry`), so
/// merely creating a workout template does not increment any numbers —
/// matching the rest of the app's "performed vs. planned" distinction.
class MuscleTrainingAnalyticsPage extends StatefulWidget {
  const MuscleTrainingAnalyticsPage({super.key});

  @override
  State<MuscleTrainingAnalyticsPage> createState() =>
      _MuscleTrainingAnalyticsPageState();
}

class _MuscleTrainingAnalyticsPageState
    extends State<MuscleTrainingAnalyticsPage> {
  _AnalyticsPeriod _period = _AnalyticsPeriod.week;

  void _setPeriod(_AnalyticsPeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Muscle Training Analytics',
      showBackButton: true,
      useNavigationRail: true,
      body: Column(
        children: [
          _HeroHeader(
            period: _period,
            onChanged: _setPeriod,
            theme: theme,
          ),
          Expanded(
            child: _AnalyticsBody(period: _period),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.period,
    required this.onChanged,
    required this.theme,
  });

  final _AnalyticsPeriod period;
  final ValueChanged<_AnalyticsPeriod> onChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final range = _rangeForPeriod(period);
    final label = period == _AnalyticsPeriod.week
        ? 'This Week'
        : DateFormat.MMMM().format(range.start);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppTheme.deepGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.deepCrimson.withValues(alpha: 0.4),
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
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MUSCLE ANALYTICS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'How often each body part is trained',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.md),
          _PeriodToggle(period: period, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.period, required this.onChanged});

  final _AnalyticsPeriod period;
  final ValueChanged<_AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PeriodChip(
              label: 'This Week',
              selected: period == _AnalyticsPeriod.week,
              onTap: () => onChanged(_AnalyticsPeriod.week),
            ),
          ),
          Expanded(
            child: _PeriodChip(
              label: 'This Month',
              selected: period == _AnalyticsPeriod.month,
              onTap: () => onChanged(_AnalyticsPeriod.month),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.period});

  final _AnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    final range = _rangeForPeriod(period);
    // Resolve use cases once per build (cheap, but stable per rebuild).
    final logsUsecase = getIt<WatchLogsInRange>();
    final entriesUsecase = getIt<WatchEntriesInRange>();
    final getWorkoutsByIds = getIt<GetWorkoutsByIds>();

    return StreamBuilder(
      stream: logsUsecase(range).asyncMap((logsEither) async {
        final logs = logsEither.getOrElse((_) => const <WorkoutLog>[]);

        // Entries and workouts can be fetched in parallel — neither
        // depends on the other for its inputs.
        final entriesFuture = entriesUsecase(range).first;
        // We don't know the workout ids until entries arrive, so resolve
        // entries first then fan out the workout lookup. Skipping this
        // would mean either re-streaming or guessing ids.
        final entriesEither = await entriesFuture;
        final entries =
            entriesEither.getOrElse((_) => const <WorkoutLogEntry>[]);
        final distinctWorkoutIds = <int>{
          for (final e in entries) e.workoutId,
        }..remove(0);
        final workoutsEither = await getWorkoutsByIds(
          distinctWorkoutIds.toList(),
        );
        final workoutsById =
            workoutsEither.getOrElse((_) => const <int, Workout>{});

        return _AnalyticsSnapshot(
          logs: logs,
          entries: entries,
          workoutsById: workoutsById,
        );
      }),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: AppLoadingIndicator());
        }
        final snapshot = snap.data as _AnalyticsSnapshot;
        if (snapshot.entries.isEmpty) {
          return _EmptyState(period: period);
        }
        return _AnalyticsView(snapshot: snapshot, period: period);
      },
    );
  }
}

/// Immutable snapshot of one analytics emission. Counts and the
/// distinct-day total are computed once at construction so the view
/// only reads them — never recomputes per build.
class _AnalyticsSnapshot {
  _AnalyticsSnapshot({
    required this.logs,
    required this.entries,
    required this.workoutsById,
  })  : distinctDays = _computeDistinctDays(logs),
        muscleCounts = _computeMuscleCounts(entries, workoutsById),
        groupCounts = _computeGroupCounts(entries, workoutsById);

  final List<WorkoutLog> logs;
  final List<WorkoutLogEntry> entries;
  final Map<int, Workout> workoutsById;
  final int distinctDays;
  final Map<BodyPart, int> muscleCounts;
  final Map<MuscleGroup, int> groupCounts;

  static int _computeDistinctDays(List<WorkoutLog> logs) {
    final days = <DateTime>{};
    for (final l in logs) {
      days.add(
        DateTime(l.performedAt.year, l.performedAt.month, l.performedAt.day),
      );
    }
    return days.length;
  }

  static Map<BodyPart, int> _computeMuscleCounts(
    List<WorkoutLogEntry> entries,
    Map<int, Workout> workoutsById,
  ) {
    final counts = <BodyPart, int>{};
    for (final entry in entries) {
      final part = workoutsById[entry.workoutId]?.targetedBodyPart;
      if (part == null) continue;
      counts[part] = (counts[part] ?? 0) + 1;
    }
    return counts;
  }

  static Map<MuscleGroup, int> _computeGroupCounts(
    List<WorkoutLogEntry> entries,
    Map<int, Workout> workoutsById,
  ) {
    final counts = <MuscleGroup, int>{};
    for (final entry in entries) {
      final part = workoutsById[entry.workoutId]?.targetedBodyPart;
      if (part == null) continue;
      final parent = MuscleGroupHierarchy.parentOf(part);
      if (parent == null) continue;
      counts[parent] = (counts[parent] ?? 0) + 1;
    }
    return counts;
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView({required this.snapshot, required this.period});

  final _AnalyticsSnapshot snapshot;
  final _AnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    final total = snapshot.groupCounts.values.fold<int>(0, (a, b) => a + b);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _TotalsCard(
          totalMuscleWorkouts: total,
          distinctDays: snapshot.distinctDays,
          period: period,
        ),
        const Gap(AppSpacing.lg),
        for (final group in MuscleGroup.values)
          ..._buildGroupSection(
            group: group,
            snapshot: snapshot,
            period: period,
          ),
      ],
    );
  }

  List<Widget> _buildGroupSection({
    required MuscleGroup group,
    required _AnalyticsSnapshot snapshot,
    required _AnalyticsPeriod period,
  }) {
    final groupCount = snapshot.groupCounts[group] ?? 0;
    if (groupCount == 0) return const <Widget>[];
    // Show only children that were actually trained, in picker order,
    // so the page stays focused.
    final children = MuscleGroupHierarchy.childrenOf(group)
        .where((p) => (snapshot.muscleCounts[p] ?? 0) > 0)
        .toList();
    return [
      _MuscleGroupSection(
        group: group,
        groupCount: groupCount,
        children: children,
        childCounts: {
          for (final part in children) part: snapshot.muscleCounts[part] ?? 0,
        },
        period: period,
      ),
      const Gap(AppSpacing.md),
    ];
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.totalMuscleWorkouts,
    required this.distinctDays,
    required this.period,
  });

  final int totalMuscleWorkouts;
  final int distinctDays;
  final _AnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppTheme.freshGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.limeGreen.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(label: 'WORKOUTS', value: '$totalMuscleWorkouts'),
          ),
          Container(
            width: 1,
            height: 44,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          Expanded(
            child: _Stat(label: 'ACTIVE DAYS', value: '$distinctDays'),
          ),
          Container(
            width: 1,
            height: 44,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          Expanded(
            child: _Stat(
              label: 'PERIOD',
              value: period.name.toUpperCase(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const Gap(2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MuscleGroupSection extends StatelessWidget {
  const _MuscleGroupSection({
    required this.group,
    required this.groupCount,
    required this.children,
    required this.childCounts,
    required this.period,
  });

  final MuscleGroup group;
  final int groupCount;
  final List<BodyPart> children;
  final Map<BodyPart, int> childCounts;
  final _AnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  group.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      group.label.toUpperCase(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      'Overall ${group.label}: $groupCount ${groupCount == 1 ? 'workout' : 'workouts'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _CountBadge(count: groupCount),
            ],
          ),
          const Gap(AppSpacing.sm),
          Container(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          const Gap(AppSpacing.sm),
          for (final part in children) ...[
            _MuscleRow(
              key: ValueKey(part),
              part: part,
              count: childCounts[part] ?? 0,
              period: period,
            ),
            if (part != children.last) const Gap(AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _MuscleRow extends StatelessWidget {
  const _MuscleRow({
    super.key,
    required this.part,
    required this.count,
    required this.period,
  });

  final BodyPart part;
  final int count;
  final _AnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.pushNamed(
            RouteNames.muscleAnalyticsDetail,
            pathParameters: {'part': part.id},
            queryParameters: {
              'period': period == _AnalyticsPeriod.week ? 'week' : 'month',
            },
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    part.icon,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: Text(
                    part.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _CountPill(count: count),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.period});

  final _AnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = period == _AnalyticsPeriod.week ? 'this week' : 'this month';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.deepGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.deepCrimson.withValues(alpha: 0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.fitness_center_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
            ),
            const Gap(AppSpacing.md),
            Text(
              'No muscle training data yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              'Complete a workout with a targeted body part to see $label statistics here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The parent muscle groups surfaced on the analytics page. Enum order
/// is the visual order shown to the user.
enum MuscleGroup {
  chest,
  back,
  shoulders,
  arms,
  legs,
  core,
}

extension MuscleGroupX on MuscleGroup {
  String get label => switch (this) {
        MuscleGroup.chest => 'Chest',
        MuscleGroup.back => 'Back',
        MuscleGroup.shoulders => 'Shoulders',
        MuscleGroup.arms => 'Arms',
        MuscleGroup.legs => 'Legs',
        MuscleGroup.core => 'Core',
      };

  IconData get icon => switch (this) {
        MuscleGroup.chest => Icons.favorite_rounded,
        MuscleGroup.back => Icons.accessibility_rounded,
        MuscleGroup.shoulders => Icons.accessibility_new_rounded,
        MuscleGroup.arms => Icons.fitness_center_rounded,
        MuscleGroup.legs => Icons.directions_run_rounded,
        MuscleGroup.core => Icons.donut_small_rounded,
      };
}

/// Maps each leaf [BodyPart] to its parent [MuscleGroup]. Misc values
/// (`cardio`, `fullBody`, `other`) intentionally have no parent — they
/// aren't a "muscle" so rolling them up would distort the per-group
/// chart.
class MuscleGroupHierarchy {
  const MuscleGroupHierarchy._();

  // Single source of truth: which body parts roll up into which group.
  // Declaration order matches the body-part picker the user uses to
  // tag workouts, so the analytics page is consistent with the rest
  // of the app.
  static const Map<MuscleGroup, List<BodyPart>> _children = {
    MuscleGroup.chest: [
      BodyPart.upperChest,
      BodyPart.lowerChest,
      BodyPart.fullChest,
    ],
    MuscleGroup.back: [BodyPart.back, BodyPart.lats],
    MuscleGroup.shoulders: [
      BodyPart.shoulders,
      BodyPart.frontDelts,
      BodyPart.rearDelts,
      BodyPart.traps,
    ],
    MuscleGroup.arms: [
      BodyPart.biceps,
      BodyPart.triceps,
      BodyPart.forearms,
      BodyPart.wrists,
    ],
    MuscleGroup.legs: [
      BodyPart.quads,
      BodyPart.hamstrings,
      BodyPart.glutes,
      BodyPart.calves,
      BodyPart.fullLegs,
    ],
    MuscleGroup.core: [
      BodyPart.upperAbs,
      BodyPart.lowerAbs,
      BodyPart.obliques,
      BodyPart.core,
    ],
  };

  static MuscleGroup? parentOf(BodyPart part) {
    for (final entry in _children.entries) {
      if (entry.value.contains(part)) return entry.key;
    }
    return null;
  }

  static List<BodyPart> childrenOf(MuscleGroup group) {
    return _children[group] ?? const <BodyPart>[];
  }
}

/// First-midnight-of-week → first-midnight-of-next-week (Sun-anchored,
/// matching the calendar's column layout: Sun, Mon, Tue, ... Sat).
DateRange _rangeForPeriod(_AnalyticsPeriod period) {
  final now = DateTime.now();
  if (period == _AnalyticsPeriod.week) {
    // weekday: Mon=1..Sun=7. Anchor on the most recent Sunday.
    final today = DateTime(now.year, now.month, now.day);
    final sundayOffset = today.weekday % DateTime.daysPerWeek;
    final start = today.subtract(Duration(days: sundayOffset));
    final end = start.add(const Duration(days: 7));
    return DateRange(start: start, end: end);
  }
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 1);
  return DateRange(start: start, end: end);
}
