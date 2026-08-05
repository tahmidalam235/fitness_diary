import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/usecase/no_params.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../domain/usecases/set_day_frozen.dart';
import '../../domain/usecases/watch_frozen_days.dart';

/// Full-screen "freeze day" page.
///
/// Renders the last 30 days as a horizontal strip of toggle chips.
/// Tapping a chip dispatches [SetDayFrozen] which inserts or removes
/// the freeze row in the database. The stream subscription ([WatchFrozenDays])
/// keeps the UI in sync — no extra state to manage locally.
class FreezePage extends StatefulWidget {
  const FreezePage({super.key});

  @override
  State<FreezePage> createState() => _FreezePageState();
}

class _FreezePageState extends State<FreezePage> {
  late final WatchFrozenDays _watch = getIt<WatchFrozenDays>();
  late final SetDayFrozen _set = getIt<SetDayFrozen>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppScaffold(
      title: l10n.historyFreezeTitle,
      showBackButton: true,
      body: StreamBuilder<Set<DateTime>>(
        stream: _watch(
          const NoParams(),
        ).map((either) => either.getOrElse((_) => const <DateTime>{})),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const AppLoadingIndicator();
          }
          final frozen = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.ac_unit_rounded, color: Color(0xFF60A5FA)),
                    const Gap(AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.historyFreezeHelp,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.lg),
              Text(
                'LAST 30 DAYS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const Gap(AppSpacing.sm),
              _FreezeStrip(
                frozen: frozen,
                onToggle: (day, shouldFreeze) => _toggle(day, shouldFreeze),
              ),
              const Gap(AppSpacing.lg),
              if (frozen.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    l10n.historyFreezeEmpty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                _FrozenList(frozen: frozen),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggle(DateTime day, bool shouldFreeze) async {
    final result = await _set(
      SetDayFrozenParams(day: day, frozen: shouldFreeze),
    );
    if (!mounted) return;
    result.fold((failure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }, (_) {});
  }
}

/// Horizontal strip of the last 30 days. Each cell is a tap-to-toggle
/// chip.
class _FreezeStrip extends StatelessWidget {
  const _FreezeStrip({required this.frozen, required this.onToggle});

  final Set<DateTime> frozen;
  final void Function(DateTime day, bool shouldFreeze) onToggle;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 30 days inclusive of today, oldest first.
    final days = List<DateTime>.generate(
      30,
      (i) => today.subtract(Duration(days: 29 - i)),
    );

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: days.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.xs),
        itemBuilder: (context, i) {
          final day = days[i];
          final isFrozen = frozen.contains(day);
          return _FreezeChip(
            day: day,
            frozen: isFrozen,
            onTap: () => onToggle(day, !isFrozen),
          );
        },
      ),
    );
  }
}

class _FreezeChip extends StatelessWidget {
  const _FreezeChip({
    required this.day,
    required this.frozen,
    required this.onTap,
  });

  final DateTime day;
  final bool frozen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekday = DateFormat.E().format(day).toUpperCase();
    final dayNum = day.day.toString();
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: frozen
                ? theme.colorScheme.primary.withValues(alpha: 0.18)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: frozen
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: frozen ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekday,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: frozen
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              const Gap(2),
              Text(
                dayNum,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: frozen
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              const Gap(2),
              Icon(
                frozen
                    ? Icons.ac_unit_rounded
                    : (isToday ? Icons.bolt_rounded : Icons.circle_outlined),
                size: 14,
                color: frozen
                    ? theme.colorScheme.primary
                    : (isToday
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List below the strip showing the currently-frozen days with their
/// exact dates. Empty when no days are frozen.
class _FrozenList extends StatelessWidget {
  const _FrozenList({required this.frozen});

  final Set<DateTime> frozen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = frozen.toList()..sort((a, b) => b.compareTo(a));
    final fmt = DateFormat.yMMMMEEEEd();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FROZEN DAYS (${sorted.length})',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const Gap(AppSpacing.sm),
        for (final d in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                const Icon(
                  Icons.ac_unit_rounded,
                  size: 16,
                  color: Color(0xFF60A5FA),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: Text(fmt.format(d), style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
