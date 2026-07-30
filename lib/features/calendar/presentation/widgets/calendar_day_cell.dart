import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// One day cell in the calendar grid.
///
/// Renders the day number, an indicator dot when workouts were completed
/// on this day, and a gradient ring around today.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    required this.date,
    required this.inCurrentMonth,
    required this.isToday,
    required this.workoutCount,
    required this.onTap,
    super.key,
  });

  final DateTime date;
  final bool inCurrentMonth;
  final bool isToday;
  final int workoutCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = !inCurrentMonth;
    final hasWorkout = workoutCount > 0;

    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: disabled
          ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
          : theme.colorScheme.onSurface,
      fontWeight: isToday || hasWorkout ? FontWeight.w700 : FontWeight.w500,
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
          color: hasWorkout && !isToday
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
              : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isToday
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
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
                color: isToday ? Colors.white : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            if (hasWorkout)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  gradient: isToday ? null : AppTheme.heroGradient,
                  color: isToday
                      ? Colors.white.withValues(alpha: 0.95)
                      : null,
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
