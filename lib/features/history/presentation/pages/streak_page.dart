import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/usecase/no_params.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../domain/usecases/watch_frozen_days.dart';

/// Full-screen "Streak" page.
///
/// Streams workout logs + frozen days and renders the current consecutive-
/// day streak using the same `_computeStreak` algorithm that
/// [DrawerProgressSection] uses for its badge. Kept intentionally small to
/// surface just the streak number, plus this-year and all-time totals.
class StreakPage extends StatefulWidget {
  const StreakPage({super.key});

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage> {
  late final WatchFrozenDays _watchFrozen = getIt<WatchFrozenDays>();

  late final Stream<_StreakStats> _stream = _buildStream();

  Stream<_StreakStats> _buildStream() {
    final dao = getIt<WorkoutLogDao>();
    return dao.watchAllLogs().asyncMap((logs) async {
      final frozenEither = await _watchFrozen(const NoParams()).first;
      final frozen = frozenEither.getOrElse((_) => const <DateTime>{});

      final workoutDays = <DateTime>{};
      for (final log in logs) {
        workoutDays.add(
          DateTime(
            log.performedAt.year,
            log.performedAt.month,
            log.performedAt.day,
          ),
        );
      }

      final now = DateTime.now();
      final thisYear = logs.where((l) => l.performedAt.year == now.year).length;

      return _StreakStats(
        streakDays: _computeStreak(workoutDays, frozen, now),
        frozenDays: frozen.length,
        thisYearCount: thisYear,
        totalCount: logs.length,
      );
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Streak',
      showBackButton: true,
      body: StreamBuilder<_StreakStats>(
        stream: _stream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const AppLoadingIndicator();
          }
          final stats = snap.data!;
          final active = stats.streakDays > 0;
          final accent = active
              ? const Color(0xFFFB923C)
              : theme.colorScheme.outline;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              // Hero card with the big streak number.
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppTheme.warmGradient,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          active
                              ? Icons.local_fire_department_rounded
                              : Icons.bedtime_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const Gap(AppSpacing.sm),
                        Text(
                          'CURRENT STREAK',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const Gap(AppSpacing.md),
                    Text(
                      '${stats.streakDays}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      stats.streakDays == 1 ? 'day' : 'days',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (stats.frozenDays > 0) ...[
                      const Gap(AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF60A5FA,
                          ).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.ac_unit_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const Gap(AppSpacing.xs),
                            Text(
                              '${stats.frozenDays} freeze day'
                              '${stats.frozenDays == 1 ? '' : 's'} this period',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'THIS YEAR',
                      value: '${stats.thisYearCount}',
                      accent: const Color(0xFF22D3EE),
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: _MiniStat(
                      label: 'ALL TIME',
                      value: '${stats.totalCount}',
                      accent: const Color(0xFFA78BFA),
                    ),
                  ),
                ],
              ),
              const Gap(AppSpacing.lg),
              // Reuse the badge style from the drawer section so the
              // visual identity stays consistent.
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: active ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: accent.withValues(alpha: active ? 0.5 : 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      active
                          ? Icons.local_fire_department_rounded
                          : Icons.bedtime_rounded,
                      color: accent,
                      size: 20,
                    ),
                    const Gap(AppSpacing.sm),
                    Expanded(
                      child: Text(
                        active
                            ? 'You\'ve trained (or rested on a freeze) '
                                  '${stats.streakDays} day'
                                  '${stats.streakDays == 1 ? '' : 's'} in a row.'
                            : 'Log a workout or freeze a day to start a '
                                  'new streak.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreakStats {
  const _StreakStats({
    required this.streakDays,
    required this.frozenDays,
    required this.thisYearCount,
    required this.totalCount,
  });

  final int streakDays;
  final int frozenDays;
  final int thisYearCount;
  final int totalCount;
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
