import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
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
                  _CalendarHero(
                    month: _visibleMonth,
                    workoutsThisMonth: state.workoutsByDay.entries
                        .where(
                          (e) =>
                              e.key.year == _visibleMonth.year &&
                              e.key.month == _visibleMonth.month,
                        )
                        .fold<int>(0, (sum, e) => sum + e.value),
                    workoutsByDay: state.workoutsByDay,
                    onTap: _pickMonth,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
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

/// Compact hero header for the calendar page — month label, year,
/// workouts-this-month chip and the picker trigger.
class _CalendarHero extends StatelessWidget {
  const _CalendarHero({
    required this.month,
    required this.workoutsThisMonth,
    required this.workoutsByDay,
    required this.onTap,
  });

  final DateTime month;
  final int workoutsThisMonth;
  final Map<DateTime, int> workoutsByDay;
  final VoidCallback onTap;

  /// Number of distinct days in the current calendar week (Sunday →
  /// Saturday, matching the grid column order) that have at least one
  /// completed workout. Matches what the grid renders as a dot, so
  /// the hero metric stays in sync with what the user sees below it.
  int get workoutsThisWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday % 7));
    final weekEnd = weekStart.add(const Duration(days: 7));
    var days = 0;
    for (final entry in workoutsByDay.entries) {
      if (!entry.key.isBefore(weekStart) &&
          entry.key.isBefore(weekEnd) &&
          entry.value > 0) {
        days += 1;
      }
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.calendarTitle.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat.yMMMM(l10n.localeName).format(month),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.expand_more_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'PICK',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        icon: Icons.bolt_rounded,
                        value: '$workoutsThisMonth',
                        label: 'WORKOUTS',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _HeroMetric(
                        icon: Icons.event_available_rounded,
                        value: '$workoutsThisWeek',
                        label: 'THIS WEEK',
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
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 9,
            ),
          ),
        ],
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
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
