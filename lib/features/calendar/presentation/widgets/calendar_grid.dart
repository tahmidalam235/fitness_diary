import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import 'calendar_day_cell.dart';

/// 7-column, 6-row calendar grid. Pure Flutter (no `table_calendar` dep).
///
/// Renders weekday headers on top and 42 day cells below. Cells outside
/// the current month render in a disabled style; tapping them is a no-op.
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    required this.month,
    required this.daysWithLogs,
    required this.workoutsByDay,
    required this.onTapDay,
    super.key,
  });

  /// First day (midnight) of the visible month.
  final DateTime month;

  /// Set of date-only values that have at least one completed log.
  final Set<DateTime> daysWithLogs;

  /// Map of date → log count for badge display.
  final Map<DateTime, int> workoutsByDay;

  final ValueChanged<DateTime> onTapDay;

  /// Returns the half-open list of 42 dates starting on the Sunday of
  /// the week containing [month]'s first day.
  List<DateTime> _buildGridDates() {
    final first = DateTime(month.year, month.month, 1);
    final sundayOffset = first.weekday % 7; // Mon=1..Sun=7 -> 1..0
    final start = first.subtract(Duration(days: sundayOffset));
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

    final labels = <String>[
      l10n.calendarWeekdaySun,
      l10n.calendarWeekdayMon,
      l10n.calendarWeekdayTue,
      l10n.calendarWeekdayWed,
      l10n.calendarWeekdayThu,
      l10n.calendarWeekdayFri,
      l10n.calendarWeekdaySat,
    ];

    final dates = _buildGridDates();

    return LayoutBuilder(
      builder: (context, constraints) {
        // The 7-column grid needs ~52dp per cell to keep day numbers and
        // the completion dot legible. If the available height is shorter
        // than that (e.g. landscape phones, split-screen, small tablets)
        // we let the whole calendar scroll vertically instead of squashing
        // cells into unreadable slivers.
        const minCellExtent = 48.0;
        const gridHeight = (minCellExtent * 6) + 4;
        final gridFits = constraints.maxHeight >= gridHeight;
        return Column(
          children: [
            Row(
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
            ),
            const Gap(AppSpacing.xs),
            Expanded(
              child: gridFits
                  ? GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
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
                    )
                  : SingleChildScrollView(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xs,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisExtent: minCellExtent,
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
                    ),
            ),
          ],
        );
      },
    );
  }
}