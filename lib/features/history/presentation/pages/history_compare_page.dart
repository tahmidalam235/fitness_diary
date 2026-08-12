import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../calendar/presentation/widgets/month_year_picker.dart';
import '../../../workout_log/domain/entities/workout_log.dart';
import '../../domain/usecases/watch_logs_in_range.dart';

/// Full-screen "compare two time ranges" view.
class HistoryComparePage extends StatefulWidget {
  const HistoryComparePage({
    required this.rangeA,
    required this.rangeB,
    super.key,
  });

  final DateTime rangeA;
  final DateTime rangeB;

  @override
  State<HistoryComparePage> createState() => _HistoryComparePageState();
}

class _HistoryComparePageState extends State<HistoryComparePage> {
  late DateTime _a;
  late DateTime _b;

  @override
  void initState() {
    super.initState();
    _a = widget.rangeA;
    _b = widget.rangeB;
  }

  DateTime _endOf(DateTime month) {
    return DateTime(month.year, month.month + 1, 1);
  }

  Future<void> _pickMonth({required bool isA}) async {
    final initial = isA ? _a : _b;
    final now = DateTime.now();
    final picked = await MonthYearPicker.show(
      context: context,
      initial: initial,
      minYear: now.year - 5,
      maxYear: now.year + 1,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isA) {
        _a = picked;
      } else {
        _b = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rangeA = DateRange(start: _a, end: _endOf(_a));
    final rangeB = DateRange(start: _b, end: _endOf(_b));

    return AppScaffold(
      title: l10n.historyCompareTitle,
      showBackButton: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            'COMPARE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            'Pick a month for each range',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _RangeHeaderCard(
                  label: l10n.historyCompareRangeA,
                  range: _a,
                  gradient: AppTheme.heroGradient,
                  onTap: () => _pickMonth(isA: true),
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: _RangeHeaderCard(
                  label: l10n.historyCompareRangeB,
                  range: _b,
                  gradient: AppTheme.warmGradient,
                  onTap: () => _pickMonth(isA: false),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _RangeColumn(
                  range: rangeA,
                  accentColor: const Color(0xFF3B82F6),
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: _RangeColumn(
                  range: rangeB,
                  accentColor: const Color(0xFFFB923C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeHeaderCard extends StatelessWidget {
  const _RangeHeaderCard({
    required this.label,
    required this.range,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final DateTime range;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthLabel = DateFormat.yMMMM().format(range);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const Gap(AppSpacing.xs),
              Text(
                monthLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Gap(AppSpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.edit_calendar_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const Gap(AppSpacing.xs),
                  Text(
                    'Tap to change',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                    ),
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

class _RangeColumn extends StatelessWidget {
  const _RangeColumn({required this.range, required this.accentColor});

  final DateRange range;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usecase = getIt<WatchLogsInRange>();

    return StreamBuilder<_RangeData>(
      stream: usecase(range).asyncMap((either) async {
        final logs = either.getOrElse((_) => const <WorkoutLog>[]);
        int sets = 0;
        final dao = getIt<WorkoutLogDao>();
        for (final l in logs) {
          final entries = await dao.getEntriesForLogById(l.id);
          sets += entries.length;
        }
        return _RangeData(logs: logs, totalSets: sets);
      }),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Container(
            height: 280,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: const AppLoadingIndicator(),
          );
        }
        final data = snap.data!;
        return _RangeSummary(
          data: data,
          range: range,
          accentColor: accentColor,
        );
      },
    );
  }
}

class _RangeData {
  const _RangeData({required this.logs, required this.totalSets});
  final List<WorkoutLog> logs;
  final int totalSets;
}

class _RangeSummary extends StatelessWidget {
  const _RangeSummary({
    required this.data,
    required this.range,
    required this.accentColor,
  });

  final _RangeData data;
  final DateRange range;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final logs = data.logs;
    final distinctDays = <DateTime>{};
    for (final l in logs) {
      distinctDays.add(
        DateTime(l.performedAt.year, l.performedAt.month, l.performedAt.day),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KpiTile(
          label: 'Workouts',
          value: '${logs.length}',
          accentColor: accentColor,
        ),
        const Gap(AppSpacing.sm),
        _KpiTile(
          label: 'Active days',
          value: '${distinctDays.length}',
          accentColor: accentColor,
        ),
        const Gap(AppSpacing.sm),
        _KpiTile(
          label: 'Total sets',
          value: '${data.totalSets}',
          accentColor: accentColor,
        ),
        const Gap(AppSpacing.md),
        _DayStrip(logs: logs, range: range, accentColor: accentColor),
      ],
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.logs,
    required this.range,
    required this.accentColor,
  });

  final List<WorkoutLog> logs;
  final DateRange range;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = range.start;
    final lastExclusive = range.end;
    final dayCount = lastExclusive.difference(first).inDays;
    final activeDays = <int>{
      for (final l in logs)
        if (!l.performedAt.isBefore(first) &&
            l.performedAt.isBefore(lastExclusive))
          l.performedAt.day,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var i = 0; i < dayCount; i++)
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: activeDays.contains(first.add(Duration(days: i)).day)
                    ? accentColor
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accentColor.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
