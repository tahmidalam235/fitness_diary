import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../features/workout/domain/entities/body_part.dart';
import '../../features/workout/domain/entities/workout.dart';
import '../../features/workout_log/domain/entities/workout_log_entry.dart';
import 'app_section_header.dart';

/// Premium workout card used in lists (today, session details, history,
/// etc.). Encapsulates the full visual treatment: gradient position
/// avatar, title, body-part chip, sets/reps/weight/duration stat chips,
/// notes, and a trailing action slot.
class AppWorkoutCard extends StatelessWidget {
  const AppWorkoutCard({
    required this.workout,
    this.entry,
    this.position,
    this.onTap,
    this.trailing,
    this.dragHandle,
    this.leading,
    this.completed = false,
    super.key,
  });

  final Workout workout;
  final WorkoutLogEntry? entry;
  final int? position;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? dragHandle;
  final Widget? leading;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use entry values (today's progress) if they exist, otherwise the
    // workout template defaults.
    final sets = entry?.sets ?? workout.defaultSets;
    final reps = entry?.reps ?? workout.defaultReps;
    final weight = entry?.weight ?? workout.defaultWeight;
    final duration = entry?.durationSeconds ?? workout.defaultDurationSeconds;
    String notes = workout.notes;
    final entryNotes = entry?.notes;
    if (entryNotes != null && entryNotes.isNotEmpty) {
      notes = entryNotes;
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: completed
              ? theme.colorScheme.primary.withValues(alpha: 0.6)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (dragHandle != null) ...[
                      dragHandle!,
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (position != null) ...[
                      _PositionAvatar(position: position!),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        workout.exerciseName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: completed
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (completed)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          gradient: AppTheme.freshGradient,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    if (trailing != null) trailing!,
                  ],
                ),
                if (workout.targetedBodyPart != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _BodyPartChip(part: workout.targetedBodyPart!),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppStatChip(
                      label: 'SETS',
                      value: '$sets',
                      icon: Icons.format_list_numbered_rounded,
                    ),
                    AppStatChip(
                      label: 'REPS',
                      value: '$reps',
                      icon: Icons.repeat_rounded,
                    ),
                    if (weight != null)
                      AppStatChip(
                        label: 'WEIGHT',
                        value:
                            '${weight == weight.toInt() ? weight.toInt() : weight} kg',
                        icon: Icons.fitness_center_rounded,
                      ),
                    if (duration != null)
                      AppStatChip(
                        label: 'DURATION',
                        value: '${(duration / 60).round()}m',
                        icon: Icons.timer_outlined,
                      ),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    notes,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionAvatar extends StatelessWidget {
  const _PositionAvatar({required this.position});
  final int position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
        boxShadow: [
          BoxShadow(
            color: Color(0x406366F1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$position',
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _BodyPartChip extends StatelessWidget {
  const _BodyPartChip({required this.part});
  final BodyPart part;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(part.icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            part.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium session-style card with a gradient avatar and layered shadow.
class AppSessionCard extends StatelessWidget {
  const AppSessionCard({
    required this.title,
    this.description,
    this.workoutCount,
    this.onTap,
    this.trailing,
    this.leading,
    super.key,
  });

  final String title;
  final String? description;
  final int? workoutCount;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = title.isEmpty ? '?' : title[0].toUpperCase();
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (leading != null)
                  leading!
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x406366F1),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null && description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (workoutCount != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fitness_center_rounded,
                                size: 12,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '$workoutCount workout${workoutCount == 1 ? '' : 's'}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
