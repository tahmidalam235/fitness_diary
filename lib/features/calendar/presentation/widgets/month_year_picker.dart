import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

/// Modal month-year picker.
///
/// Shows a year header with prev/next buttons (clamped to [minYear] and
/// [maxYear]) and a 4×3 grid of the 12 months. The currently selected
/// month is highlighted; tapping any month dismisses the dialog with
/// [DateTime(y, m, 1)] returned.
///
/// `showDialog(...)` is the intended entry point. The picker is
/// stateless; the caller owns the initial value and applies the result.
class MonthYearPicker extends StatefulWidget {
  const MonthYearPicker({
    required this.initial,
    required this.minYear,
    required this.maxYear,
    super.key,
  });

  /// First-of-month starting value (time component is ignored).
  final DateTime initial;

  /// Inclusive lower bound on the selectable year.
  final int minYear;

  /// Inclusive upper bound on the selectable year.
  final int maxYear;

  /// Convenience helper that wraps the picker in a Material dialog and
  /// resolves to the chosen [DateTime] or `null` if dismissed.
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initial,
    required int minYear,
    required int maxYear,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (_) => MonthYearPicker(
        initial: initial,
        minYear: minYear,
        maxYear: maxYear,
      ),
    );
  }

  @override
  State<MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<MonthYearPicker> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
  }

  void _stepYear(int delta) {
    final next = _year + delta;
    if (next < widget.minYear || next > widget.maxYear) return;
    setState(() => _year = next);
  }

  void _pickMonth(int m) {
    Navigator.of(context).pop(DateTime(_year, m, 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final canPrev = _year > widget.minYear;
    final canNext = _year < widget.maxYear;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.calendarPickerTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(AppSpacing.md),
              Row(
                children: [
                  IconButton(
                    onPressed: canPrev ? () => _stepYear(-1) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: l10n.calendarPickerYearPrev,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_year',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: canNext ? () => _stepYear(1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: l10n.calendarPickerYearNext,
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
                childAspectRatio: 1.4,
                children: [
                  for (var m = 1; m <= 12; m++)
                    _MonthChip(
                      label: DateFormat.MMM(locale)
                          .format(DateTime(_year, m, 1)),
                      selected: m == _month && _year == widget.initial.year,
                      onTap: () => _pickMonth(m),
                    ),
                ],
              ),
              const Gap(AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.calendarPickerCancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}