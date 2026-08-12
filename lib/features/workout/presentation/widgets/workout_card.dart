import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/workout.dart';

/// Compact card representing a [Workout] inside a session details list.
///
/// Premium touches:
/// - layered shadow that responds to theme brightness
/// - subtle gradient avatar with the workout position as a glyph
/// - refined chips with primary-tinted background and proper padding
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({
    required this.workout,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.dragHandle,
    this.leading,
    super.key,
  });

  final Workout workout;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget dragHandle;

  /// Optional leading widget (e.g. a checkbox for the pick-for-today
  /// flow). When provided the card's `onTap` is suppressed so the
  /// checkbox can absorb taps without triggering navigation.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: leading == null ? onTap : null,
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: layeredShadow(colorScheme: theme.colorScheme),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                dragHandle,
                if (leading != null) ...[const Gap(AppSpacing.xs), leading!],
                const Gap(AppSpacing.xs),
                _PositionAvatar(position: workout.position + 1),
                const Gap(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.exerciseName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const Gap(AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          _Chip(
                            icon: Icons.format_list_numbered_rounded,
                            label: l10n.workoutListSetsReps(
                              workout.defaultSets,
                              workout.defaultReps,
                            ),
                          ),
                          if (workout.defaultDurationSeconds != null)
                            _Chip(
                              icon: Icons.schedule_rounded,
                              label: l10n.workoutListDuration(
                                (workout.defaultDurationSeconds! / 60).round(),
                              ),
                            ),
                          if (workout.defaultWeight != null)
                            _Chip(
                              icon: Icons.fitness_center_rounded,
                              label: l10n.workoutListWeight(
                                _formatWeight(workout.defaultWeight!),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_WorkoutCardAction>(
                  tooltip: '',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _WorkoutCardAction.edit:
                        onEdit();
                      case _WorkoutCardAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _WorkoutCardAction.edit,
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 20),
                          const Gap(AppSpacing.sm),
                          Text(l10n.workoutActionEdit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _WorkoutCardAction.delete,
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                          const Gap(AppSpacing.sm),
                          Text(
                            l10n.workoutActionDelete,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

enum _WorkoutCardAction { edit, delete }

/// Small gradient pill with leading icon — used for sets/reps/duration/weight.
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onPrimaryContainer),
          const Gap(AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient avatar showing the workout's 1-based position number.
class _PositionAvatar extends StatelessWidget {
  const _PositionAvatar({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        position.toString(),
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
