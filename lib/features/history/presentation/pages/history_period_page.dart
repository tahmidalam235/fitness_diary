import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../session/domain/entities/session.dart';
import '../../../session/presentation/bloc/session_bloc.dart';
import '../../../session/presentation/bloc/session_event.dart';
import '../../../session/presentation/bloc/session_state.dart';
import '../../../workout_log/data/models/workout_log_model.dart';
import '../../../workout_log/domain/entities/workout_log.dart';

/// Drill-down page for a specific month or year of workout history.
///
/// Args (passed via `extra`):
///   * `period`  → `'month'` or `'year'`.
///   * `year`    → int.
///   * `month`   → int? (1–12, required for month).
///
/// Streams [WorkoutLog]s from the local DB and groups them by day, then
/// resolves session names via [SessionBloc] so each card shows the
/// template name instead of just an ID.
class HistoryPeriodPage extends StatelessWidget {
  const HistoryPeriodPage({
    required this.period,
    required this.year,
    this.month,
    super.key,
  });

  final String period;
  final int year;
  final int? month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = period == 'month'
        ? '${_monthName(month ?? 1)} $year'
        : '$year';

    final range = period == 'month'
        ? _monthRange(year, month!)
        : _yearRange(year);

    return AppScaffold(
      title: title,
      showBackButton: true,
      body: BlocProvider<SessionBloc>(
        create: (_) => getIt<SessionBloc>()..add(const WatchSessionsEvent()),
        child: _HistoryPeriodView(
          period: period,
          year: year,
          month: month,
          rangeStart: range.$1,
          rangeEnd: range.$2,
          l10n: l10n,
        ),
      ),
    );
  }

  static String _monthName(int m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[(m - 1).clamp(0, 11)];
  }

  static (DateTime, DateTime) _monthRange(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (start, end);
  }

  static (DateTime, DateTime) _yearRange(int year) {
    return (DateTime(year, 1, 1), DateTime(year + 1, 1, 1));
  }
}

class _HistoryPeriodView extends StatefulWidget {
  const _HistoryPeriodView({
    required this.period,
    required this.year,
    required this.month,
    required this.rangeStart,
    required this.rangeEnd,
    required this.l10n,
  });

  final String period;
  final int year;
  final int? month;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final AppLocalizations l10n;

  @override
  State<_HistoryPeriodView> createState() => _HistoryPeriodViewState();
}

class _HistoryPeriodViewState extends State<_HistoryPeriodView> {
  late final Stream<List<WorkoutLog>> _logsStream;

  @override
  void initState() {
    super.initState();
    _logsStream = _buildStream();
  }

  Stream<List<WorkoutLog>> _buildStream() {
    final dao = getIt<WorkoutLogDao>();
    return dao
        .watchLogsInRange(start: widget.rangeStart, end: widget.rangeEnd)
        .map(
          (models) => <WorkoutLog>[
            for (final WorkoutLogModel m in models) m.toEntity(),
          ],
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        final sessionsById = <int, Session>{
          for (final s
              in (sessionState is SessionLoaded
                  ? sessionState.sessions
                  : const <Session>[]))
            if (s.id != null) s.id!: s,
        };

        return StreamBuilder<List<WorkoutLog>>(
          stream: _logsStream,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const AppLoadingIndicator();
            }
            final logs = snap.data!;
            if (logs.isEmpty) {
              return _EmptyState(
                theme: theme,
                message: widget.l10n.historyPeriodEmpty,
              );
            }

            // Group by day.
            final byDay = <DateTime, List<WorkoutLog>>{};
            for (final log in logs) {
              final day = DateTime(
                log.performedAt.year,
                log.performedAt.month,
                log.performedAt.day,
              );
              byDay.putIfAbsent(day, () => []).add(log);
            }
            final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                _SummaryHeader(
                  totalWorkouts: logs.length,
                  distinctDays: byDay.length,
                  sessions: sessionsById.length,
                  theme: theme,
                ),
                const Gap(AppSpacing.xl),
                ...days.map((day) {
                  final dayLogs = byDay[day]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _DaySection(
                      day: day,
                      logs: dayLogs,
                      sessionsById: sessionsById,
                      theme: theme,
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.totalWorkouts,
    required this.distinctDays,
    required this.sessions,
    required this.theme,
  });

  final int totalWorkouts;
  final int distinctDays;
  final int sessions;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(label: 'WORKOUTS', value: '$totalWorkouts'),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _Stat(label: 'DAYS', value: '$distinctDays'),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _Stat(label: 'SESSIONS', value: '$sessions'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const Gap(2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.logs,
    required this.sessionsById,
    required this.theme,
  });

  final DateTime day;
  final List<WorkoutLog> logs;
  final Map<int, Session> sessionsById;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('EEEE, MMM d').format(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
          child: Text(
            dayLabel.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        ...logs.map(
          (log) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _WorkoutLogCard(
              log: log,
              session: sessionsById[log.sessionId],
              theme: theme,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutLogCard extends StatelessWidget {
  const _WorkoutLogCard({
    required this.log,
    required this.session,
    required this.theme,
  });

  final WorkoutLog log;
  final Session? session;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final name = session?.name.isNotEmpty == true
        ? session!.name
        : 'Session #${log.sessionId}';
    final subtitle = session?.description.isNotEmpty == true
        ? session!.description
        : 'Tap to view workout details.';
    final time = DateFormat('h:mm a').format(log.performedAt);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (session?.id != null) {
            context.pushNamed(
              RouteNames.sessionDetails,
              pathParameters: {'id': session!.id!.toString()},
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme, required this.message});
  final ThemeData theme;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(40),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.event_busy_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const Gap(AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
