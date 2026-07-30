import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../bloc/calendar_state.dart';
import '../widgets/month_section.dart';

/// Total number of months rendered by the all-months calendar view.
///
/// 20 years × 12 = 240. The bloc subscribes to the equivalent window
/// (Jan 1 of `now - 10y` through Jan 1 of `now + 11y`) and exposes the
/// full set of completed-day dates so the view can slice by month
/// without any per-month resubscription.
const int _kTotalMonths = 240;

/// All-months Calendar page.
///
/// - Renders a vertical scroll of [_kTotalMonths] months (-10y to +10y).
/// - Each row is a [MonthSection] with its own header + 7×6 grid.
/// - Tap a day → `/calendar/day/yyyy-MM-dd`.
/// - Opens scrolled to today's month via a [GlobalKey] anchor and
///   [Scrollable.ensureVisible] scheduled in a post-frame callback
///   (the list is lazy, so we can't compute a fixed pixel offset).
/// - The "Today" FAB jumps back to today's month.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final ScrollController _controller;
  late final List<DateTime> _months;
  late final int _todayIndex;
  final GlobalKey _todayKey = GlobalKey(debugLabel: 'calendar-today-month');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _months = List<DateTime>.generate(
      _kTotalMonths,
      (i) => DateTime(now.year - 10 + (i ~/ 12), 1 + (i % 12), 1),
    );
    _todayIndex = _months.indexWhere(
      (m) => m.year == now.year && m.month == now.month,
    );
    _controller = ScrollController();

    // Defer the jump until after the first frame so the lazy
    // ListView has actually laid out the target item, then scroll to
    // it via [Scrollable.ensureVisible] using a [GlobalKey] anchor.
    if (_todayIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _todayKey.currentContext;
        if (ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: 0,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDayParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void _jumpToToday() {
    final ctx = _todayKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0,
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
                    child: ListView.builder(
                      controller: _controller,
                      itemCount: _months.length,
                      itemBuilder: (context, index) {
                        final month = _months[index];
                        return MonthSection(
                          key: index == _todayIndex ? _todayKey : null,
                          month: month,
                          daysWithLogs: state.daysWithLogs,
                          workoutsByDay: state.workoutsByDay,
                          onTapDay: (d) => context.pushNamed(
                            RouteNames.calendarDay,
                            pathParameters: {'date': _formatDayParam(d)},
                          ),
                        );
                      },
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