import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../history/domain/entities/daily_log_group.dart';
import '../../../session/domain/entities/session.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import 'day_set_summary_tile.dart';

/// Card showing one [DailyLogGroup] (a single session performed on the
/// day) on the Daily Details page.
class DayLogCard extends StatelessWidget {
  const DayLogCard({
    required this.group,
    required this.sessionsById,
    required this.workoutsById,
    super.key,
  });

  final DailyLogGroup group;
  final Map<int, Session> sessionsById;
  final Map<int, Workout> workoutsById;

  /// Group entries by workout id so each workout renders as a section
  /// inside the card.
  Map<int, List<WorkoutLogEntry>> _entriesByWorkout() {
    final m = <int, List<WorkoutLogEntry>>{};
    for (final e in group.entries) {
      m.putIfAbsent(e.workoutId, () => <WorkoutLogEntry>[]).add(e);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final sections = _entriesByWorkout();
    final sessionName =
        sessionsById[group.log.sessionId]?.name ??
        l10n.dailyDetailsSessionFallback(group.log.sessionId);
    final workoutCount = sections.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const Gap(AppSpacing.xs),
                Expanded(
                  child: Text(
                    sessionName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$workoutCount '
                  '${workoutCount == 1 ? 'workout' : 'workouts'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.sm),
            for (final entry in sections.entries)
              DaySetSummaryTile(
                entry: entry.value.first,
                workoutName:
                    workoutsById[entry.key]?.exerciseName ?? '',
              ),
            if (sections.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  l10n.dailyDetailsEmptyMessage,
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
