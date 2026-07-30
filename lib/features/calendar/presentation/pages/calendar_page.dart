import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import '../widgets/calendar_grid.dart';

/// Monthly Calendar page.
///
/// - Header: month-year label + prev/next + "Today" jump button.
/// - Body: 7×6 day grid with workout-completed dots.
/// - Tap a day → `/calendar/day/yyyy-MM-dd`.
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  String _monthLabel(BuildContext context, DateTime month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  String _formatDayParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Returns the normalized first-of-month DateTime for the month
  /// [delta] months away from [current]. Dart's `DateTime` constructor
  /// silently rolls over (e.g. month 0 → previous December), so this
  /// is purely a clarity wrapper — we still rely on Dart's overflow
  /// semantics for year/month wrapping.
  DateTime _stepMonth(DateTime current, int delta) {
    final next = DateTime(current.year, current.month + delta, 1);
    return DateTime(next.year, next.month, 1);
  }

  void _changeMonth(BuildContext context, DateTime current, int delta) {
    context.read<CalendarBloc>().add(
          MonthChangedEvent(_stepMonth(current, delta)),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider<CalendarBloc>(
      create: (_) => getIt<CalendarBloc>(),
      child: AppScaffold(
        title: l10n.calendarTitle,
        useNavigationRail: true,
        showBackButton: true,
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
                  _CalendarHeader(
                    month: state.visibleMonth,
                    isCurrentMonth: state.isCurrentMonth,
                    label: _monthLabel(context, state.visibleMonth),
                    onPrev: () => _changeMonth(context, state.visibleMonth, -1),
                    onNext: () => _changeMonth(context, state.visibleMonth, 1),
                    onToday: () => context
                        .read<CalendarBloc>()
                        .add(const JumpToTodayEvent()),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: _LegendChip(label: l10n.calendarLegendCompleted),
                  ),
                  Expanded(
                    child: CalendarGrid(
                      month: state.visibleMonth,
                      daysWithLogs: state.daysWithLogs,
                      workoutsByDay: state.workoutsByDay,
                      onTapDay: (d) => context.pushNamed(
                        RouteNames.calendarDay,
                        pathParameters: {'date': _formatDayParam(d)},
                      ),
                    ),
                  ),
                ],
              );
            }
            // Fallback for any future state we don't yet render.
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.month,
    required this.isCurrentMonth,
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final bool isCurrentMonth;
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: l10n.calendarMonthPrev,
                onPressed: onPrev,
              ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
              _RoundIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: l10n.calendarMonthNext,
                onPressed: onNext,
              ),
            ],
          ),
          if (!isCurrentMonth) ...[
            const Gap(AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onToday,
                icon: const Icon(Icons.today_rounded, size: 18),
                label: Text(l10n.calendarToday),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Filled tonal circular icon button used in the calendar header.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0x1A000000)),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon),
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
            const Gap(AppSpacing.xs),
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