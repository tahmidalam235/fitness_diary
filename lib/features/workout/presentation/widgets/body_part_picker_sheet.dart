import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/body_part.dart';

/// Modal bottom-sheet picker for [BodyPart].
///
/// Returns:
/// - The selected [BodyPart] when the user taps a row.
/// - `null` when the user taps "Clear" (explicit reset) or dismisses
///   the sheet by tapping the scrim.
///
/// Callers must treat the result as a "user explicitly chose `null`"
/// signal: they should update state whether the picker returns a value
/// or `null` (distinguished from "user dismissed without changing"
/// only by the explicit Clear tap, which also returns `null`). To keep
/// the contract simple, callers update their state unconditionally and
/// rely on the fact that the picker wouldn't have been opened for
/// nothing.
class BodyPartPickerSheet extends StatelessWidget {
  const BodyPartPickerSheet({required this.initial, super.key});

  final BodyPart? initial;

  /// Convenience entry point. Mirrors `MonthYearPicker.show`'s shape.
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
      builder: (ctx) => BodyPartPickerSheet(initial: initial),
    );
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
                    l10n.workoutFieldTargetedBodyPart,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.sm),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: BodyPart.values.length + 1,
                separatorBuilder: (_, _) =>
                    const Gap(AppSpacing.xs),
                // Index 0 is "Clear"; the rest are BodyPart.values.
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _ClearRow(
                      label: l10n.workoutTargetedBodyPartClear,
                      onTap: () => Navigator.of(context).pop(null),
                    );
                  }
                  final part = BodyPart.values[index - 1];
                  final selected = initial == part;
                  return _BodyPartRow(
                    part: part,
                    selected: selected,
                    onTap: () => Navigator.of(context).pop(part),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyPartRow extends StatelessWidget {
  const _BodyPartRow({
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
    return Material(
      color: selected
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
                part.icon,
                size: 22,
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Text(
                  part.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (selected)
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

class _ClearRow extends StatelessWidget {
  const _ClearRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
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
                Icons.close_rounded,
                size: 22,
                color: theme.colorScheme.error,
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
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
