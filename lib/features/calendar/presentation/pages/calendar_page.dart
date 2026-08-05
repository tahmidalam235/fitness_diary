import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_state.dart';
import '../widgets/month_section.dart';
import '../widgets/month_year_picker.dart';

/// First-of-month for the picker — bounds match the all-months version
/// (-10y / +10y from today) so users can still browse any month.
int _minYear() => DateTime.now().year - 10;
int _maxYear() => DateTime.now().year + 10;

/// Single-month Calendar page.
///
/// - Renders the currently visible [MonthSection] only (no scroll,
///   no chevrons).
/// - A sticky tappable month-year bar above the grid opens the
///   [MonthYearPicker]; picking a month updates the visible month
///   in place.
/// - The "Today" FAB jumps back to today's month.
/// - Tap a day → `/calendar/day/yyyy-MM-dd`.
///
/// Note: the bloc still subscribes to the full 20-year window so the
/// workout-completion dots on whatever month is visible reflect the
/// full history without any resubscription.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() => _visibleMonth = DateTime(now.year, now.month, 1));
  }

  Future<void> _pickMonth() async {
    final picked = await MonthYearPicker.show(
      context: context,
      initial: _visibleMonth,
      minYear: _minYear(),
      maxYear: _maxYear(),
    );
    if (picked == null || !mounted) return;
    setState(() => _visibleMonth = picked);
  }

  String _formatDayParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider<CalendarBloc>(
      create: (_) => getIt<CalendarBloc>(),
      child: AppScaffold(
        title: l10n.calendarTitle,
        useNavigationRail: true,
        titleLeadingIcon: true,
        floatingActionButton: FloatingActionButton.small(
          onPressed: _jumpToToday,
          tooltip: l10n.calendarToday,
          child: const Icon(Icons.today_rounded),
        ),
        body: BlocBuilder<CalendarBloc, CalendarState>(
          builder: (context, state) {
            if (state is CalendarInitial || state is CalendarLoading) {
              return const AppLoadingIndicator();
            }
            if (state is CalendarError) {
              return AppEmptyState(
                title: l10n.commonErrorTitle,
                message: state.failure.message,
                icon: Icons.error_outline_rounded,
              );
            }
            if (state is CalendarLoaded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MonthYearBar(
                    label: DateFormat.yMMMM(
                      l10n.localeName,
                    ).format(_visibleMonth),
                    onTap: _pickMonth,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: _LegendChip(label: l10n.calendarLegendCompleted),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      child: MonthSection(
                        month: _visibleMonth,
                        daysWithLogs: state.daysWithLogs,
                        workoutsByDay: state.workoutsByDay,
                        onTapDay: (d) => context.pushNamed(
                          RouteNames.calendarDay,
                          pathParameters: {'date': _formatDayParam(d)},
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

/// Sticky tappable bar showing the currently visible month. Built
/// from AppScaffold's body so it sits above the month grid.
class _MonthYearBar extends StatelessWidget {
  const _MonthYearBar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
