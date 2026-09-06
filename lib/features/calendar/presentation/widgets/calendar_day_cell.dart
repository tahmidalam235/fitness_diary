import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// One day cell in the calendar grid.
///
/// Renders the day number, an indicator dot when workouts were completed
/// on this day, a gradient ring around today, and a subtle blueish fill
/// when the day is a freeze/rest day.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    required this.date,
    required this.inCurrentMonth,
    required this.isToday,
    required this.workoutCount,
    required this.onTap,
    this.isFrozen = false,
    super.key,
  });

  final DateTime date;
  final bool inCurrentMonth;
  final bool isToday;
  final int workoutCount;
  final VoidCallback onTap;

  /// True when this day is marked as a freeze/rest day. Frozen days
  /// get a subtle blueish appearance so they're immediately
  /// recognizable in the grid.
  final bool isFrozen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = !inCurrentMonth;
    final hasWorkout = workoutCount > 0;

    // Freeze takes visual priority over a workout-day tint when both
    // happen on the same date so the blueish appearance is never
    // hidden behind the orangish workout fill.
    final showFrozenTint = isFrozen && !isToday;

    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: disabled
          ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
          : theme.colorScheme.onSurface,
      fontWeight: isToday || hasWorkout || isFrozen
          ? FontWeight.w700
          : FontWeight.w500,
      letterSpacing: -0.2,
    );

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: showFrozenTint
              ? AppTheme.frostBlue.withValues(alpha: 0.18)
              : (hasWorkout && !isToday
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
                    : null),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isToday
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : (isFrozen
                    ? Border.all(
                        color: AppTheme.frostBlue.withValues(alpha: 0.55),
                        width: 1,
                      )
                    : null),
          gradient: isToday ? AppTheme.heroGradient : null,
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: baseStyle?.copyWith(
                color: isToday
                    ? Colors.white
                    : (isFrozen
                          ? AppTheme.frostBlue
                          : null),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            if (isFrozen && !isToday)
              Icon(
                Icons.ac_unit_rounded,
                size: 12,
                color: AppTheme.frostBlue,
              )
            else if (hasWorkout)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  gradient: isToday ? null : AppTheme.heroGradient,
                  color: isToday ? Colors.white.withValues(alpha: 0.95) : null,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
