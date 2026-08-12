import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../workout/domain/entities/body_part.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';

/// Compact key-value tile for a single set on the Daily Details page.
///
/// Renders set index, reps, weight, duration, and notes. Missing values
/// (e.g. a cardio set with no weight) are simply omitted.
class DaySetSummaryTile extends StatelessWidget {
  const DaySetSummaryTile({
    required this.entry,
    required this.workoutName,
    this.targetedBodyPart,
    super.key,
  });

  final WorkoutLogEntry entry;
  final String workoutName;

  /// Optional body part the workout targets. When non-null a small
  /// icon + label chip is added alongside the existing chips so the
  /// user can see which muscle group the exercise belongs to.
  final BodyPart? targetedBodyPart;

  String _formatDuration(int seconds) {
    return '${(seconds / 60).round()}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[];

    if (entry.sets != null) {
      chips.add(_Chip(label: 'Sets', value: entry.sets!.toString()));
    }
    if (entry.reps != null) {
      chips.add(
        _Chip(
          label: l10n.dailyDetailsCompletedReps,
          value: entry.reps!.toString(),
        ),
      );
    }
    if (entry.weight != null) {
      chips.add(
        _Chip(
          label: l10n.dailyDetailsWeightUsed,
          value: '${entry.weight!.toStringAsFixed(1)} kg',
        ),
      );
    }
    if (entry.durationSeconds != null) {
      chips.add(
        _Chip(
          label: l10n.dailyDetailsDuration,
          value: _formatDuration(entry.durationSeconds!),
        ),
      );
    }
    if (targetedBodyPart != null) {
      chips.add(
        _BodyPartChip(bodyPart: targetedBodyPart!),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const Gap(AppSpacing.xs),
                Expanded(
                  child: Text(
                    workoutName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (chips.isNotEmpty) ...[
              const Gap(AppSpacing.xs),
              Wrap(spacing: AppSpacing.xs, runSpacing: 4, children: chips),
            ],
            if (entry.notes.isNotEmpty) ...[
              const Gap(AppSpacing.xxs),
              Text(
                entry.notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Small chip showing the workout's targeted body part. Distinct from
/// the label/value `_Chip` because it carries an icon + a coloured
/// tinted background to match the body-part chip on the workout card.
class _BodyPartChip extends StatelessWidget {
  const _BodyPartChip({required this.bodyPart});

  final BodyPart bodyPart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            bodyPart.icon,
            size: 12,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const Gap(AppSpacing.xxs),
          Text(
            bodyPart.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
