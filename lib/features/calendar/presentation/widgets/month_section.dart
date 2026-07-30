import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import 'calendar_day_cell.dart';

/// A single month's worth of calendar grid, rendered as one row in the
/// vertically-scrolling all-months calendar view.
///
/// Renders the month-year label, weekday header, and a 7-column × 6-row
/// grid of [CalendarDayCell]s. Days outside [month] are rendered in a
/// disabled style; tapping them is a no-op.
class MonthSection extends StatelessWidget {
  const MonthSection({
    required this.month,
    required this.daysWithLogs,
    required this.workoutsByDay,
    required this.onTapDay,
    this.sectionKey,
    super.key,
  });

  /// First day (midnight) of the month this section represents.
  final DateTime month;

  /// Set of date-only values that have at least one completed log.
  final Set<DateTime> daysWithLogs;

  /// Map of date → log count for badge display.
  final Map<DateTime, int> workoutsByDay;

  /// Called when a day inside [month] is tapped.
  final ValueChanged<DateTime> onTapDay;

  /// Optional key attached to the section's outer widget so the page
  /// can use [Scrollable.ensureVisible] to scroll to a specific month
  /// (e.g. today's month).
  final Key? sectionKey;

  /// Returns the 42 dates for this month's grid: a Sunday-start 6-row
  /// window covering the leading/trailing days that fall outside
  /// [month].
  List<DateTime> _buildGridDates() {
    final sundayOffset = month.weekday % 7; // Mon=1..Sun=7 → 1..0
    final start = DateTime(month.year, month.month, 1)
        .subtract(Duration(days: sundayOffset));
    return List<DateTime>.generate(
      42,
      (i) => DateTime(start.year, start.month, start.day + i),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final monthLabel = DateFormat.yMMMM(l10n.localeName).format(month);
    final dates = _buildGridDates();

    return Padding(
      key: sectionKey,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: Text(
                    monthLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                Text(
                  l10n.calendarWeekdaySun, // pad-left to align month labels
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 0,
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.xs),
          const _WeekdayHeader(),
          const Gap(AppSpacing.xxs),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 44,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
            ),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final d = dates[index];
              final dOnly = DateTime(d.year, d.month, d.day);
              return CalendarDayCell(
                date: d,
                inCurrentMonth: d.month == month.month,
                isToday: dOnly == todayOnly,
                workoutCount: workoutsByDay[dOnly] ?? 0,
                onTap: () => onTapDay(d),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 7-column header (Sun..Sat). Centralised so every month section
/// aligns identically.
class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final labels = <String>[
      l10n.calendarWeekdaySun,
      l10n.calendarWeekdayMon,
      l10n.calendarWeekdayTue,
      l10n.calendarWeekdayWed,
      l10n.calendarWeekdayThu,
      l10n.calendarWeekdayFri,
      l10n.calendarWeekdaySat,
    ];
    return Row(
      children: [
        for (final l in labels)
          Expanded(
            child: Center(
              child: Text(
                l,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}