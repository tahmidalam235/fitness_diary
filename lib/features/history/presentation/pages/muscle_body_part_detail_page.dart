import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../workout/domain/entities/body_part.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import '../../domain/usecases/get_workouts_by_ids.dart';
import '../../domain/usecases/watch_entries_in_range.dart';
import '../../domain/usecases/watch_logs_in_range.dart';

enum _DetailPeriod { week, month }

/// Drill-down page for a single targeted body part.
///
/// Shows every workout name performed for that body part during the
/// selected period, alongside aggregated sets / reps / weight / duration.
/// Pure read-only — derives everything from completed workout entries
/// in the chosen date range.
class MuscleBodyPartDetailPage extends StatefulWidget {
  const MuscleBodyPartDetailPage({
    required this.bodyPartId,
    required this.period,
    super.key,
  });

  /// `BodyPart.id` (enum name) — passed via the route's `:part` param.
  final String bodyPartId;

  /// `'week'` or `'month'`. Resolved from the parent page's toggle.
  final String period;

  @override
  State<MuscleBodyPartDetailPage> createState() =>
      _MuscleBodyPartDetailPageState();
}

class _MuscleBodyPartDetailPageState extends State<MuscleBodyPartDetailPage> {
  late final BodyPart? _part;
  late final _DetailPeriod _period;
  late final DateTime _rangeStart;
  late final DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    _part = BodyPart.fromId(widget.bodyPartId);
    _period = widget.period == 'month'
        ? _DetailPeriod.month
        : _DetailPeriod.week;
    final range = _rangeForPeriod(_period);
    _rangeStart = range.start;
    _rangeEnd = range.end;
  }

  @override
  Widget build(BuildContext context) {
    final part = _part;
    if (part == null) {
      return AppScaffold(
        title: 'Body Part',
        showBackButton: true,
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text('Unknown body part.'),
          ),
        ),
      );
    }

    return AppScaffold(
      title: part.label,
      showBackButton: true,
      useNavigationRail: true,
      body: Column(
        children: [
          _HeroHeader(
            part: part,
            period: _period,
            rangeStart: _rangeStart,
            rangeEnd: _rangeEnd,
          ),
          Expanded(child: _DetailBody(part: part)),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.part,
    required this.period,
    required this.rangeStart,
    required this.rangeEnd,
  });

  final BodyPart part;
  final _DetailPeriod period;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = period == _DetailPeriod.week
        ? 'This Week'
        : DateFormat.MMMM().format(rangeStart);

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
              child: Icon(part.icon, color: Colors.white, size: 30),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    part.label.toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
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

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.part});

  final BodyPart part;

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_MuscleBodyPartDetailPageState>()!;
    final range = DateRange(start: state._rangeStart, end: state._rangeEnd);
    final logsUsecase = getIt<WatchLogsInRange>();
    final entriesUsecase = getIt<WatchEntriesInRange>();
    final getWorkoutsByIds = getIt<GetWorkoutsByIds>();

    return StreamBuilder(
      stream: logsUsecase(range).asyncMap((logsEither) async {
        final logs = logsEither.getOrElse((_) => const []);

        final entriesEither = await entriesUsecase(range).first;
        final entries =
            entriesEither.getOrElse((_) => const <WorkoutLogEntry>[]);

        // Filter to entries whose workout targeted this body part.
        // Master-workout lookup happens up-front so we can read
        // `targetedBodyPart` and `exerciseName`.
        final distinctWorkoutIds = <int>{
          for (final e in entries) e.workoutId,
        }..remove(0);
        final workoutsEither = await getWorkoutsByIds(
          distinctWorkoutIds.toList(),
        );
        final workoutsById =
            workoutsEither.getOrElse((_) => const <int, Workout>{});

        final filtered = entries.where((e) {
          final w = workoutsById[e.workoutId];
          return w?.targetedBodyPart == part;
        }).toList();

        // Aggregate by exercise name. Some workouts may share a name
        // across different `workoutId` ints (legacy data); group on the
        // int id first so each workout's totals stay separate, then
        // collapse to a display name key for the rendered list.
        final perIdTotals = <int, _WorkoutTotals>{};
        for (final e in filtered) {
          final w = workoutsById[e.workoutId];
          if (w == null) continue;
          final entry = perIdTotals.putIfAbsent(
            e.workoutId,
            () => _WorkoutTotals(name: w.exerciseName),
          );
          entry.add(e);
        }
        final list = perIdTotals.values.toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return _DetailSnapshot(workouts: list, logsCount: logs.length);
      }),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: AppLoadingIndicator());
        }
        final data = snap.data as _DetailSnapshot;
        if (data.workouts.isEmpty) {
          return _EmptyState(part: part);
        }
        return _WorkoutList(workouts: data.workouts);
      },
    );
  }
}

class _DetailSnapshot {
  const _DetailSnapshot({required this.workouts, required this.logsCount});
  final List<_WorkoutTotals> workouts;
  final int logsCount;
}

class _WorkoutTotals {
  _WorkoutTotals({required this.name});
  final String name;
  int sets = 0;
  int reps = 0;
  double weight = 0;
  int durationSeconds = 0;

  /// True when at least one entry contributed to this row's sets,
  /// reps, weight, or duration. Used to decide whether to render the
  /// "no detail" fallback.
  bool get hasAny => sets > 0 || reps > 0 || weight > 0 || durationSeconds > 0;

  void add(WorkoutLogEntry e) {
    if (e.sets != null) sets += e.sets!;
    if (e.reps != null) reps += e.reps!;
    if (e.weight != null) weight += e.weight!;
    if (e.durationSeconds != null) durationSeconds += e.durationSeconds!;
  }
}

class _WorkoutList extends StatelessWidget {
  const _WorkoutList({required this.workouts});

  final List<_WorkoutTotals> workouts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: workouts.length,
      separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
      itemBuilder: (context, i) {
        final w = workouts[i];
        return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: Text(
                      w.name.isEmpty ? 'Workout' : w.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              if (w.hasAny) ...[
                const Gap(AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _StatChip(label: 'Sets', value: '${w.sets}'),
                    _StatChip(label: 'Reps', value: '${w.reps}'),
                    _StatChip(label: 'Weight', value: _formatWeight(w.weight)),
                    _StatChip(label: 'Duration', value: _formatDuration(w.durationSeconds)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
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
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.part});
  final BodyPart part;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                child: Icon(
                  part.icon,
                  size: 44,
                  color: Colors.white,
                ),
              ),
            ),
            const Gap(AppSpacing.md),
            Text(
              'No workouts recorded for this body part yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DateRange _rangeForPeriod(_DetailPeriod period) {
  final now = DateTime.now();
  if (period == _DetailPeriod.week) {
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

String _formatWeight(double w) {
  if (w == 0) return '0kg';
  return w == w.toInt() ? '${w.toInt()}kg' : '${w.toStringAsFixed(1)}kg';
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return '0m';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}
