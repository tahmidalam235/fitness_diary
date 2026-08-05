import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/usecase/no_params.dart';
import '../../../history/domain/usecases/watch_frozen_days.dart';

/// Collapsible "Progress" section embedded in the [AppDrawer]. Streams
/// workout-log data from the local Drift database and renders:
///
///   * **Streak counter** in the header (current consecutive-day streak).
///   * **Mini KPIs** for this year + all time.
///   * **Monthly bar chart** of the last 12 months (tap to drill down).
///   * **Yearly totals** (tap to drill down).
///   * **GitHub-style heatmap** of the last 12 weeks.
class DrawerProgressSection extends StatefulWidget {
  const DrawerProgressSection({this.initiallyExpanded = false, super.key});

  /// When true, the section renders expanded on first build. Used by
  /// the standalone History overview page so the user lands on the
  /// full breakdown instead of having to tap the header.
  final bool initiallyExpanded;

  @override
  State<DrawerProgressSection> createState() => _DrawerProgressSectionState();
}

class _DrawerProgressSectionState extends State<DrawerProgressSection> {
  late bool _expanded;

  late final Stream<_ProgressSnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _stream = _buildStream();
  }

  Stream<_ProgressSnapshot> _buildStream() {
    final dao = getIt<WorkoutLogDao>();
    final watchFrozen = getIt<WatchFrozenDays>();

    final controller = StreamController<_ProgressSnapshot>();

    void update() async {
      final logs = await dao.watchAllLogs().first;
      final frozenResult = await watchFrozen(const NoParams()).first;
      final frozenDays = frozenResult.getOrElse((_) => const <DateTime>{});

      final byMonth = <String, int>{};
      final byYear = <int, int>{};
      final workoutDays = <DateTime>{};

      for (final log in logs) {
        final key =
            '${log.performedAt.year}-${log.performedAt.month.toString().padLeft(2, '0')}';
        byMonth[key] = (byMonth[key] ?? 0) + 1;
        byYear[log.performedAt.year] = (byYear[log.performedAt.year] ?? 0) + 1;
        workoutDays.add(
          DateTime(
            log.performedAt.year,
            log.performedAt.month,
            log.performedAt.day,
          ),
        );
      }

      final months = byMonth.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));
      final recentMonths = months.take(12).map((e) {
        final parts = e.key.split('-');
        return _MonthBucket(
          year: int.parse(parts[0]),
          month: int.parse(parts[1]),
          count: e.value,
        );
      }).toList();

      final years = byYear.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key));
      final recentYears = years.take(5).map((e) {
        return _YearBucket(year: e.key, count: e.value);
      }).toList();

      final now = DateTime.now();
      final thisMonthKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final thisMonthCount = byMonth[thisMonthKey] ?? 0;
      final thisYearCount = byYear[now.year] ?? 0;

      final streak = _computeStreak(workoutDays, frozenDays, now);

      if (!controller.isClosed) {
        controller.add(
          _ProgressSnapshot(
            thisMonthCount: thisMonthCount,
            thisYearCount: thisYearCount,
            totalCount: logs.length,
            streakDays: streak,
            frozenDaysCount: frozenDays.length,
            months: recentMonths,
            years: recentYears,
          ),
        );
      }
    }

    final sub1 = dao.watchAllLogs().listen((_) => update());
    final sub2 = watchFrozen(const NoParams()).listen((_) => update());

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    // Initial update
    update();

    return controller.stream;
  }

  /// Consecutive days ending today (or yesterday if today not yet
  /// worked out). A frozen day counts as a passing day so intentional
  /// rest days don't reset the streak. Returns 0 if there's no recent
  /// activity on either side.
  int _computeStreak(
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

  void _openMonth(BuildContext context, _MonthBucket m) {
    context.push(
      '${RoutePaths.historyPeriod}?period=month&year=${m.year}&month=${m.month}',
    );
  }

  void _openYear(BuildContext context, _YearBucket y) {
    context.push('${RoutePaths.historyPeriod}?period=year&year=${y.year}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<_ProgressSnapshot>(
      stream: _stream,
      builder: (context, snap) {
        final data = snap.data;
        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                expanded: _expanded,
                thisMonth: data?.thisMonthCount ?? 0,
                streakDays: data?.streakDays ?? 0,
                frozenDays: data?.frozenDaysCount ?? 0,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
              if (_expanded && data != null)
                _ExpandedBody(
                  data: data,
                  onTapMonth: (m) => _openMonth(context, m),
                  onTapYear: (y) => _openYear(context, y),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Header (always visible) ────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.expanded,
    required this.thisMonth,
    required this.streakDays,
    required this.frozenDays,
    required this.onTap,
  });

  final bool expanded;
  final int thisMonth;
  final int frozenDays;
  final int streakDays;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.insights_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Progress',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    thisMonth == 1
                        ? '1 workout this month'
                        : '$thisMonth workouts this month',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Streak badge.
            _StreakBadge(days: streakDays, frozenDays: frozenDays),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days, required this.frozenDays});

  final int days;
  final int frozenDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = days > 0;
    final color = active ? const Color(0xFFFB923C) : theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active
                ? Icons.local_fire_department_rounded
                : Icons.bedtime_rounded,
            size: 12,
            color: active ? color : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            active ? '$days' : '0',
            style: theme.textTheme.labelSmall?.copyWith(
              color: active ? color : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          if (frozenDays > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.ac_unit_rounded,
                    size: 10,
                    color: Color(0xFF60A5FA),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$frozenDays',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF60A5FA),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Expanded body ──────────────────────────────────────────────

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.data,
    required this.onTapMonth,
    required this.onTapYear,
  });

  final _ProgressSnapshot data;
  final ValueChanged<_MonthBucket> onTapMonth;
  final ValueChanged<_YearBucket> onTapYear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxMonthly = data.months.isEmpty
        ? 1
        : data.months.map((m) => m.count).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          // Yearly summary tiles.
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'THIS YEAR',
                  value: '${data.thisYearCount}',
                  accent: const Color(0xFF22D3EE),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniStat(
                  label: 'ALL TIME',
                  value: '${data.totalCount}',
                  accent: const Color(0xFFA78BFA),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 12-week heatmap.
          Text(
            'LAST 12 WEEKS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Heatmap(streakDays: data.streakDays),
          const SizedBox(height: AppSpacing.md),
          // Monthly bars.
          Row(
            children: [
              Text(
                'BY MONTH',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                'tap to view',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (data.months.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No workouts logged yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...data.months.map(
              (m) => _MonthRow(
                bucket: m,
                max: maxMonthly,
                onTap: () => onTapMonth(m),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          // Yearly summary list.
          Row(
            children: [
              Text(
                'BY YEAR',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                'tap to view',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (data.years.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No yearly totals yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...data.years.map(
              (y) => _YearRow(bucket: y, onTap: () => onTapYear(y)),
            ),
        ],
      ),
    );
  }
}

// ── Heatmap (GitHub-style 12-week grid) ────────────────────────

/// Renders a 12-week x 7-day heatmap. The heatmap is computed by
/// aggregating workout-log counts per day for the last 84 days, then
/// bucketing each day's count into 5 intensity levels (0..4) for the
/// colour ramp.
class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dao = getIt<WorkoutLogDao>();

    return StreamBuilder<List<DateTime>>(
      stream: dao.watchAllLogs().map(
        (logs) => [
          for (final log in logs)
            DateTime(
              log.performedAt.year,
              log.performedAt.month,
              log.performedAt.day,
            ),
        ],
      ),
      builder: (context, snap) {
        final days = snap.data ?? const [];
        return LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: _HeatmapGrid(
                workoutDays: days.toSet(),
                now: DateTime.now(),
                theme: theme,
              ),
            );
          },
        );
      },
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.workoutDays,
    required this.now,
    required this.theme,
  });

  final Set<DateTime> workoutDays;
  final DateTime now;
  final ThemeData theme;

  static const _weeks = 12;

  @override
  Widget build(BuildContext context) {
    // Compute start: Sunday-aligned start of the week containing
    // (today - 11 weeks). We render weeks as columns.
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = today.subtract(Duration(days: today.weekday % 7));
    final start = thisWeekStart.subtract(
      const Duration(days: 7 * (_weeks - 1)),
    );

    // Count workouts per day in the visible window.
    final counts = <DateTime, int>{};
    for (final d in workoutDays) {
      if (d.isBefore(start)) continue;
      if (d.isAfter(today)) continue;
      counts[d] = (counts[d] ?? 0) + 1;
    }

    final maxCount = counts.values.isEmpty
        ? 0
        : counts.values.reduce((a, b) => a > b ? a : b);
    final cellSize = 12.0;
    final gap = 3.0;
    final gridWidth = (_weeks * cellSize) + ((_weeks - 1) * gap);
    final gridHeight = (7 * cellSize) + (6 * gap);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels (Mon, Wed, Fri).
        Padding(
          padding: const EdgeInsets.only(right: 4, top: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (row) {
              final showLabel = row == 1 || row == 3 || row == 5;
              return SizedBox(
                width: 16,
                height: cellSize + (row < 6 ? gap : 0),
                child: showLabel
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _dayLabel(row),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              );
            }),
          ),
        ),
        SizedBox(
          width: gridWidth,
          height: gridHeight,
          child: Stack(
            children: [
              for (var w = 0; w < _weeks; w++)
                for (var d = 0; d < 7; d++)
                  Positioned(
                    left: w * (cellSize + gap),
                    top: d * (cellSize + gap),
                    width: cellSize,
                    height: cellSize,
                    child: _HeatCell(
                      date: start.add(Duration(days: w * 7 + d)),
                      count: counts[start.add(Duration(days: w * 7 + d))] ?? 0,
                      maxCount: maxCount,
                      theme: theme,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  String _dayLabel(int row) {
    switch (row) {
      case 1:
        return 'M';
      case 3:
        return 'W';
      case 5:
        return 'F';
      default:
        return '';
    }
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.date,
    required this.count,
    required this.maxCount,
    required this.theme,
  });

  final DateTime date;
  final int count;
  final int maxCount;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isFuture = date.isAfter(DateTime.now());
    final color = _intensityColor(theme, count, maxCount);
    return Tooltip(
      message:
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}: $count workout${count == 1 ? '' : 's'}',
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: isFuture
              ? theme.colorScheme.surface.withValues(alpha: 0.3)
              : color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Color _intensityColor(ThemeData theme, int count, int max) {
    if (count == 0) {
      return theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    }
    // 1..4 buckets scaled by max
    final ratio = max == 0 ? 0 : count / max;
    final base = theme.colorScheme.primary;
    if (ratio > 0.75) return base;
    if (ratio > 0.5) return base.withValues(alpha: 0.75);
    if (ratio > 0.25) return base.withValues(alpha: 0.5);
    return base.withValues(alpha: 0.3);
  }
}

// ── Month + year rows (tap → drill-down) ───────────────────────

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.bucket,
    required this.max,
    required this.onTap,
  });

  final _MonthBucket bucket;
  final int max;
  final VoidCallback onTap;

  static const _monthLabels = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = max == 0 ? 0.0 : bucket.count / max;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  '${_monthLabels[bucket.month - 1]} ${bucket.year.toString().substring(2)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio.clamp(0.05, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: AppTheme.heroGradient,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 24,
                child: Text(
                  '${bucket.count}',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearRow extends StatelessWidget {
  const _YearRow({required this.bucket, required this.onTap});

  final _YearBucket bucket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  '${bucket.year}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fitness_center_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        bucket.count == 1
                            ? '1 workout'
                            : '${bucket.count} workouts',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Models ─────────────────────────────────────────────────────

class _ProgressSnapshot {
  const _ProgressSnapshot({
    required this.thisMonthCount,
    required this.thisYearCount,
    required this.totalCount,
    required this.streakDays,
    required this.frozenDaysCount,
    required this.months,
    required this.years,
  });

  final int thisMonthCount;
  final int thisYearCount;
  final int totalCount;
  final int streakDays;
  final int frozenDaysCount;
  final List<_MonthBucket> months;
  final List<_YearBucket> years;
}

class _MonthBucket {
  const _MonthBucket({
    required this.year,
    required this.month,
    required this.count,
  });
  final int year;
  final int month;
  final int count;
}

class _YearBucket {
  const _YearBucket({required this.year, required this.count});
  final int year;
  final int count;
}
