import 'package:flutter/material.dart';

import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/settings/data/settings_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../history/domain/usecases/get_workouts_by_ids.dart';
import '../../../workout_log/data/models/workout_log_entry_model.dart';

/// Personal records: per-exercise max weight ever logged.
///
/// Aggregates `WorkoutLogEntryModel.weight` (the heaviest set) for every
/// distinct workout id across all logs, then renders them as a sorted
/// list with PRs highlighted. Streams live from
/// [WorkoutLogDao.watchAllLogs] so a new PR shows up immediately.
class PersonalRecordsPage extends StatefulWidget {
  const PersonalRecordsPage({super.key});

  @override
  State<PersonalRecordsPage> createState() => _PersonalRecordsPageState();
}

class _PersonalRecordsPageState extends State<PersonalRecordsPage> {
  final Map<int, String> _workoutNames = {};
  final Set<int> _requestedIds = {};

  Future<void> _lookupNames(List<int> ids) async {
    final missing = ids
        .where(
          (id) => !_workoutNames.containsKey(id) && !_requestedIds.contains(id),
        )
        .toList();
    if (missing.isEmpty) return;

    _requestedIds.addAll(missing);
    final getWorkouts = getIt<GetWorkoutsByIds>();
    final result = await getWorkouts(missing);

    result.fold((_) => _requestedIds.removeAll(missing), (map) {
      if (mounted) {
        setState(() {
          for (final w in map.values) {
            _workoutNames[w.workoutId] = w.exerciseName;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dao = getIt<WorkoutLogDao>();
    final settingsService = getIt<SettingsService>();

    return AppScaffold(
      title: 'Personal Records',
      showBackButton: true,
      useNavigationRail: true,
      body: ListenableBuilder(
        listenable: settingsService,
        builder: (context, _) {
          final unit = settingsService.unit;
          return StreamBuilder<List<WorkoutLogEntryModel>>(
            stream: dao.watchAllLogs().asyncMap((logs) async {
              final entries = <WorkoutLogEntryModel>[];
              for (final log in logs) {
                final logEntries = await dao.getEntriesForLogById(log.id);
                entries.addAll(logEntries);
              }
              return entries;
            }),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const AppLoadingIndicator();
              }
              final all = snap.data!;
              final withWeight = all.where((e) => e.weight != null).toList();
              if (withWeight.isEmpty) {
                return _EmptyState();
              }
              final prs = _computePrs(withWeight);

              // Trigger name lookup for these PRs
              _lookupNames(prs.map((p) => p.workoutId).toList());

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  _SummaryHero(count: prs.length, l10n: l10n),
                  const SizedBox(height: AppSpacing.lg),
                  ...prs.map(
                    (pr) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _PrCard(
                        record: pr,
                        unit: unit,
                        workoutName: _workoutNames[pr.workoutId],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<_PrRecord> _computePrs(List<WorkoutLogEntryModel> entries) {
    final byWorkout = <int, WorkoutLogEntryModel>{};
    for (final e in entries) {
      final w = e.weight ?? 0;
      final existing = byWorkout[e.workoutId];
      if (existing == null || w > (existing.weight ?? 0)) {
        byWorkout[e.workoutId] = e;
      }
    }
    return byWorkout.values
        .map(
          (e) => _PrRecord(
            workoutId: e.workoutId,
            weight: e.weight ?? 0,
            reps: e.reps ?? 0,
            loggedAt: e.createdAt ?? DateTime.now(),
          ),
        )
        .toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
  }
}

class _PrRecord {
  const _PrRecord({
    required this.workoutId,
    required this.weight,
    required this.reps,
    required this.loggedAt,
  });

  final int workoutId;
  final double weight;
  final int reps;
  final DateTime loggedAt;
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.count, required this.l10n});
  final int count;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1 ? '1 personal record' : '$count personal records',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your heaviest lift for every exercise.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrCard extends StatelessWidget {
  const _PrCard({required this.record, required this.unit, this.workoutName});

  final _PrRecord record;
  final WeightUnit unit;
  final String? workoutName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsService = getIt<SettingsService>();
    final storedKg = record.weight;
    final displayValue = settingsService.displayWeight(storedKg);
    final isWhole = displayValue.truncateToDouble() == displayValue;
    final displayText = displayValue.toStringAsFixed(isWhole ? 0 : 1);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.fitness_center_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workoutName ?? 'Exercise #${record.workoutId}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.reps} reps · ${_friendlyDate(record.loggedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$displayText ${unit.symbol}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'PR',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _friendlyDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                Icons.emoji_events_outlined,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No PRs yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Log your first workout to see your heaviest lift here.',
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
