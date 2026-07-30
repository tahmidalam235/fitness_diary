import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// Total number of months rendered by the all-months calendar view.
///
/// 20 years × 12 = 240. Spans today-10y through today+10y (inclusive).
const int _kTotalMonths = 240;

/// First-of-month for index [_kTotalMonths - 1] is `today + 10 years`,
/// so the latest year available is `today.year + 10`.
int _maxYear() => DateTime.now().year + 10;
int _minYear() => DateTime.now().year - 10;

/// All-months Calendar page.
///
/// - Renders a vertical scroll of [_kTotalMonths] months (-10y to +10y).
/// - Each row is a [MonthSection] with its own header + 7×6 grid.
/// - Tap a day → `/calendar/day/yyyy-MM-dd`.
/// - Opens scrolled to today's month via a per-month [GlobalKey] and
///   [Scrollable.ensureVisible] scheduled in a post-frame callback.
/// - Sticky month-year bar above the scroll shows the currently
///   visible month; tapping it opens [MonthYearPicker] and scrolls
///   to the picked month.
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

  /// One [GlobalKey] per month so the page can scroll to a specific
  /// month via [Scrollable.ensureVisible] without needing to compute
  /// pixel offsets (the items have varying heights).
  late final List<GlobalKey> _monthKeys;

  /// Index of the month currently at the top of the viewport. Drives
  /// the sticky header label. Updates on scroll-end.
  int _visibleIndex = 0;

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
    _visibleIndex = _todayIndex >= 0 ? _todayIndex : 0;
    _monthKeys = List<GlobalKey>.generate(
      _kTotalMonths,
      (_) => GlobalKey(),
    );
    _controller = ScrollController()..addListener(_onScroll);

    // Defer the jump until after the first frame so the lazy
    // ListView has actually laid out the target item, then scroll to
    // it via [Scrollable.ensureVisible].
    if (_todayIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToIndex(_todayIndex);
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_controller.position.userScrollDirection == ScrollDirection.idle) {
      _updateVisibleIndex();
    }
  }

  /// Finds the topmost visible month section by inspecting each
  /// [GlobalKey]'s render-object position. Runs on scroll-end; O(n)
  /// over 240 items is negligible.
  void _updateVisibleIndex() {
    if (!mounted) return;
    if (!_controller.hasClients) return;
    final viewportTop = _controller.position.pixels;
    int best = _visibleIndex;
    double bestOffset = -1;
    for (var i = 0; i < _monthKeys.length; i++) {
      final ctx = _monthKeys[i].currentContext;
      if (ctx == null) continue;
      final ro = ctx.findRenderObject();
      if (ro is! RenderBox || !ro.attached) continue;
      final renderViewport = RenderAbstractViewport.of(ro);
      final offset = renderViewport.getOffsetToReveal(ro, 0).offset;
      if (offset <= viewportTop && offset > bestOffset) {
        bestOffset = offset;
        best = i;
      }
    }
    if (best != _visibleIndex) {
      setState(() => _visibleIndex = best);
    }
  }

  void _scrollToIndex(int index) {
    if (index < 0 || index >= _monthKeys.length) return;
    final ctx = _monthKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0,
    );
  }

  void _jumpToToday() => _scrollToIndex(_todayIndex);

  Future<void> _pickMonth() async {
    final picked = await MonthYearPicker.show(
      context: context,
      initial: _months[_visibleIndex],
      minYear: _minYear(),
      maxYear: _maxYear(),
    );
    if (picked == null) return;
    final target = _months.indexWhere(
      (m) => m.year == picked.year && m.month == picked.month,
    );
    if (target < 0) return;
    if (!mounted) return;
    setState(() => _visibleIndex = target);
    _scrollToIndex(target);
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
                  _MonthYearBar(
                    label: DateFormat.yMMMM(l10n.localeName)
                        .format(_months[_visibleIndex]),
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
                    child: ListView.builder(
                      controller: _controller,
                      itemCount: _months.length,
                      itemBuilder: (context, index) {
                        final month = _months[index];
                        return MonthSection(
                          key: _monthKeys[index],
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

/// Sticky tappable bar showing the currently visible month. Built
/// from AppScaffold's body so it sits above the scrollable list.
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