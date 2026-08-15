import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
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
              _FreezeHero(
                frozenCount: frozen.length,
              ),
              const Gap(AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF60A5FA).withValues(alpha: 0.18),
                      const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF60A5FA),
                            Color(0xFF7C3AED),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF60A5FA).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.ac_unit_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.historyFreezeHelp,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    'LAST 30 DAYS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              _FreezeStrip(
                frozen: frozen,
                onToggle: (day, shouldFreeze) => _toggle(day, shouldFreeze),
              ),
              const Gap(AppSpacing.lg),
              if (frozen.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        Icons.ac_unit_outlined,
                        size: 36,
                        color: theme.colorScheme.outline,
                      ),
                      const Gap(AppSpacing.sm),
                      Text(
                        l10n.historyFreezeEmpty,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

/// Hero banner with frozen-day counter.
class _FreezeHero extends StatelessWidget {
  const _FreezeHero({required this.frozenCount});

  final int frozenCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF60A5FA),
            Color(0xFF7C3AED),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF60A5FA).withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 12),
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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.ac_unit_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'REST DAYS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$frozenCount scheduled',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap a day below to mark it as rest',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
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

/// Horizontal strip of upcoming 30 days starting from TOMORROW.
/// Each cell is a tap-to-toggle chip. The month abbreviation of the
/// first day in the strip is rendered above the chips so the user
/// always sees which month the leftmost date belongs to.
class _FreezeStrip extends StatelessWidget {
  const _FreezeStrip({required this.frozen, required this.onToggle});

  final Set<DateTime> frozen;
  final void Function(DateTime day, bool shouldFreeze) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 30 days starting from TOMORROW (today + 1) through today + 30.
    final firstDay = today.add(const Duration(days: 1));
    final days = List<DateTime>.generate(
      30,
      (i) => firstDay.add(Duration(days: i)),
    );
    final monthLabel = DateFormat.MMM().format(firstDay).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            monthLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const Gap(AppSpacing.xs),
        SizedBox(
          height: 84,
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
        ),
      ],
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
          width: 60,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: frozen
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF60A5FA),
                      Color(0xFF7C3AED),
                    ],
                  )
                : null,
            color: frozen
                ? null
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: frozen
                  ? Colors.transparent
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: frozen ? 1.5 : 1,
            ),
            boxShadow: frozen
                ? [
                    BoxShadow(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekday,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: frozen
                      ? Colors.white.withValues(alpha: 0.92)
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
                  fontWeight: FontWeight.w900,
                  color: frozen
                      ? Colors.white
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
                    ? Colors.white
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
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF60A5FA),
                    Color(0xFF7C3AED),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const Gap(AppSpacing.sm),
            Text(
              'FROZEN DAYS (${sorted.length})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const Gap(AppSpacing.sm),
        for (final d in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF60A5FA),
                          Color(0xFF7C3AED),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.ac_unit_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: Text(
                      fmt.format(d),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
