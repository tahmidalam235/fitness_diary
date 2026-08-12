import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
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
import '../../../workout/domain/entities/workout.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/watch_entries_in_range.dart';
import '../../domain/usecases/watch_logs_in_range.dart';

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
  late final Stream<List<WorkoutLogEntry>> _entriesStream;

  @override
  void initState() {
    super.initState();
    _logsStream = _buildLogsStream();
    _entriesStream = _buildEntriesStream();
  }

  Stream<List<WorkoutLog>> _buildLogsStream() {
    final useCase = WatchLogsInRange(repository: getIt());
    return useCase(
      DateRange(start: widget.rangeStart, end: widget.rangeEnd),
    ).map((either) => either.getOrElse((_) => <WorkoutLog>[]));
  }

  Stream<List<WorkoutLogEntry>> _buildEntriesStream() {
    final useCase = WatchEntriesInRange(repository: getIt());
    return useCase(
      DateRange(start: widget.rangeStart, end: widget.rangeEnd),
    ).map((either) => either.getOrElse((_) => <WorkoutLogEntry>[]));
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
          builder: (context, logsSnap) {
            return StreamBuilder<List<WorkoutLogEntry>>(
              stream: _entriesStream,
              builder: (context, entriesSnap) {
                if (!logsSnap.hasData || !entriesSnap.hasData) {
                  return const AppLoadingIndicator();
                }

                final logs = logsSnap.data!;
                final allEntries = entriesSnap.data!;

                if (logs.isEmpty && allEntries.isEmpty) {
                  return _EmptyState(
                    theme: theme,
                    message: widget.l10n.historyPeriodEmpty,
                  );
                }

                // Join logs → entries by logFirestoreId so each entry
                // can be grouped by the date of its parent log.
                final logsByFid = <String, WorkoutLog>{
                  for (final log in logs)
                    if (log.firestoreId != null)
                      log.firestoreId!: log,
                };
                final entriesByLogFid = <String, List<WorkoutLogEntry>>{};
                for (final entry in allEntries) {
                  final wlfid = entry.workoutLogFirestoreId;
                  if (wlfid == null) continue;
                  if (!logsByFid.containsKey(wlfid)) continue;
                  entriesByLogFid.putIfAbsent(wlfid, () => []).add(entry);
                }

                // Group by day.
                final byDay = <DateTime, List<WorkoutLog>>{};
                for (final log in logs) {
                  if (log.firestoreId == null) continue;
                  if (!entriesByLogFid.containsKey(log.firestoreId)) {
                    continue;
                  }
                  final day = DateTime(
                    log.performedAt.year,
                    log.performedAt.month,
                    log.performedAt.day,
                  );
                  byDay.putIfAbsent(day, () => []).add(log);
                }
                final days = byDay.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                // Build the master workoutId → Workout lookup so we
                // can render the human-friendly workout name for each
                // entry. Empty map while the future resolves; widget
                // falls back to a "Workout #id" placeholder.
                final distinctWorkoutIds = <int>{
                  for (final e in allEntries) e.workoutId,
                }..remove(0);

                return FutureBuilder<Map<int, Workout>>(
                  future: distinctWorkoutIds.isEmpty
                      ? Future.value(const <int, Workout>{})
                      : getIt<HistoryRepository>()
                          .getWorkoutsByIds(distinctWorkoutIds.toList())
                          .then(
                            (either) => either.getOrElse(
                              (_) => const <int, Workout>{},
                            ),
                          ),
                  builder: (context, workoutsSnap) {
                    final workoutsById = workoutsSnap.data ?? const <int, Workout>{};

                    // Stats calculation.
                    final totalExercises = allEntries.length;
                    final distinctDays = byDay.length;
                    final performedSessionIds = logs
                        .map((l) => l.sessionId)
                        .toSet();
                    final distinctSessions = performedSessionIds.length;

                    final dateLabelFormat = widget.period == 'month'
                        ? DateFormat('EEEE, MMM d')
                        : DateFormat('MMM d, yyyy');

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      children: [
                        _SummaryHeader(
                          totalWorkouts: totalExercises,
                          distinctDays: distinctDays,
                          sessions: distinctSessions,
                          theme: theme,
                        ),
                        const Gap(AppSpacing.xl),
                        ...days.map((day) {
                          final dayLogs = byDay[day]!;
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _DaySection(
                              day: day,
                              dayLogs: dayLogs,
                              entriesByLogFid: entriesByLogFid,
                              sessionsById: sessionsById,
                              workoutsById: workoutsById,
                              dateLabelFormat: dateLabelFormat,
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
    required this.dayLogs,
    required this.entriesByLogFid,
    required this.sessionsById,
    required this.workoutsById,
    required this.dateLabelFormat,
    required this.theme,
  });

  final DateTime day;
  final List<WorkoutLog> dayLogs;
  final Map<String, List<WorkoutLogEntry>> entriesByLogFid;
  final Map<int, Session> sessionsById;
  final Map<int, Workout> workoutsById;
  final DateFormat dateLabelFormat;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final dayLabel = dateLabelFormat.format(day);

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
        ...dayLogs.map(
          (log) {
            final session = sessionsById[log.sessionId];
            final sessionName = session?.name.isNotEmpty == true
                ? session!.name
                : 'Session #${log.sessionId}';
            final entries = (log.firestoreId == null)
                ? const <WorkoutLogEntry>[]
                : (entriesByLogFid[log.firestoreId!] ?? const []);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SessionBlock(
                sessionName: sessionName,
                entries: entries,
                workoutsById: workoutsById,
                theme: theme,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Renders one session's worth of recorded workouts under a given day:
/// session name on top, then each workout on its own row. Workouts
/// without a resolvable name fall back to "Workout #id" so the count
/// stays accurate.
class _SessionBlock extends StatelessWidget {
  const _SessionBlock({
    required this.sessionName,
    required this.entries,
    required this.workoutsById,
    required this.theme,
  });

  final String sessionName;
  final List<WorkoutLogEntry> entries;
  final Map<int, Workout> workoutsById;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      // No entries attached to this log in range — still show the
      // session header so the day isn't blank.
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          sessionName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sessionName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(AppSpacing.xs),
          ...entries.map((entry) {
            final workout = workoutsById[entry.workoutId];
            final name = workout?.exerciseName.isNotEmpty == true
                ? workout!.exerciseName
                : 'Workout #${entry.workoutId}';
            // Prefer the values saved on the entry (the actual logged
            // record for that day); fall back to the workout template
            // defaults if the user never overrode them. Missing values
            // are simply dropped from the details line.
            final sets = entry.sets ?? workout?.defaultSets;
            final reps = entry.reps ?? workout?.defaultReps;
            final weight = entry.weight ?? workout?.defaultWeight;
            final durationSeconds =
                entry.durationSeconds ?? workout?.defaultDurationSeconds;
            final target = workout?.targetedBodyPart;

            final detailParts = <String>[];
            if (sets != null) detailParts.add('Sets: $sets');
            if (reps != null) detailParts.add('Reps: $reps');
            if (weight != null) {
              final w = weight == weight.toInt()
                  ? weight.toInt().toString()
                  : weight.toString();
              detailParts.add('Weight: ${w}kg');
            }
            if (durationSeconds != null) {
              detailParts.add('Duration: ${(durationSeconds / 60).round()} min');
            }
            if (target != null) detailParts.add('Target: ${target.label}');

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: AppSpacing.sm),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (detailParts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              detailParts.join('  '),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
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
