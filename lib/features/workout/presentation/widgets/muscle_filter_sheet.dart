import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/body_part.dart';

/// Bottom-sheet picker for the muscle-wise filter on the
/// `Today → Add Workout` selection list.
///
/// Renders the six major muscle groups (Chest, Back, Shoulders, Arms,
/// Legs, Core) plus an "Other" bucket — each row is expandable and
/// reveals the underlying [BodyPart] enum values that belong to that
/// group. The mapping comes from [BodyPartGrouping] so this widget
/// stays a pure presentation layer over the existing [BodyPart] enum.
///
/// Return values:
/// - A [BodyPart] when the user picks a child muscle.
/// - `null`  when the user picks "All muscles" (clear filter) or
///   dismisses the sheet.
///
/// Callers (the session-details page) interpret the result as:
/// - `null`  → show every workout (no filter).
/// - a value → narrow the list to workouts whose
///   `Workout.targetedBodyPart` matches.
class MuscleFilterSheet extends StatefulWidget {
  const MuscleFilterSheet({required this.initial, super.key});

  /// Currently-active filter, if any. Used to pre-expand the group
  /// that contains this body part so the user can see what's picked
  /// without having to re-expand it.
  final BodyPart? initial;

  /// Convenience entry point — mirrors the `show(...)` shape used by
  /// [BodyPartPickerSheet].
  static Future<BodyPart?> show(
    BuildContext context, {
    required BodyPart? initial,
  }) {
    return showModalBottomSheet<BodyPart>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      builder: (ctx) => MuscleFilterSheet(initial: initial),
    );
  }

  @override
  State<MuscleFilterSheet> createState() => _MuscleFilterSheetState();
}

class _MuscleFilterSheetState extends State<MuscleFilterSheet> {
  /// Set of major groups the user has expanded. Stored as a set so
  /// multiple groups can be open at once without the user having to
  /// close one before opening another.
  late final Set<MajorMuscleGroup> _expanded;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _expanded = {
      if (initial != null) initial.majorGroup,
    };
  }

  void _toggle(MajorMuscleGroup group) {
    setState(() {
      if (_expanded.contains(group)) {
        _expanded.remove(group);
      } else {
        _expanded.add(group);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    l10n.workoutFilterByMuscle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.sm),
            // "All muscles" — clears the filter. Always shown at the
            // top so the user has an obvious way back to the full list.
            _ClearRow(
              label: l10n.workoutFilterAllMuscles,
              icon: Icons.all_inclusive_rounded,
              isSelected: widget.initial == null,
              onTap: () => Navigator.of(context).pop(null),
            ),
            const Gap(AppSpacing.xs),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                children: [
                  for (final group in kOrderedMajorMuscleGroups) ...[
                    _MajorGroupRow(
                      group: group,
                      isExpanded: _expanded.contains(group),
                      isActive:
                          widget.initial?.majorGroup == group,
                      onHeaderTap: () => _toggle(group),
                    ),
                    if (_expanded.contains(group)) ...[
                      for (final part in kBodyPartsByGroup[group]!)
                        _ChildRow(
                          part: part,
                          selected: widget.initial == part,
                          onTap: () => Navigator.of(context).pop(part),
                        ),
                    ],
                    const Gap(AppSpacing.xs),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tinted picker row used for both the "All muscles" clear action and
/// (visually) the body-part rows — keeps the picker rows visually
/// consistent with [BodyPartPickerSheet].
class _ClearRow extends StatelessWidget {
  const _ClearRow({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Major muscle group header — tappable, with a chevron that rotates
/// on expand/collapse.
class _MajorGroupRow extends StatelessWidget {
  const _MajorGroupRow({
    required this.group,
    required this.isExpanded,
    required this.isActive,
    required this.onHeaderTap,
  });

  final MajorMuscleGroup group;
  final bool isExpanded;
  final bool isActive;
  final VoidCallback onHeaderTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isActive
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onHeaderTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                group.icon,
                size: 22,
                color: isActive
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Text(
                  group.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Child row inside an expanded major group — picking it returns the
/// specific [BodyPart] to the caller.
class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.part,
    required this.selected,
    required this.onTap,
  });

  final BodyPart part;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  part.icon,
                  size: 18,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: Text(
                    part.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
