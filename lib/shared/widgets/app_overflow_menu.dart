import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/routes/route_paths.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/usecase/no_params.dart';
import '../../features/history/domain/usecases/set_day_frozen.dart';
import '../../features/history/domain/usecases/watch_frozen_days.dart';
import '../../l10n/app_localizations.dart';

class AppOverflowMenu extends StatelessWidget {
  const AppOverflowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final watchFrozen = getIt<WatchFrozenDays>();
    final setFrozen = getIt<SetDayFrozen>();
    final theme = Theme.of(context);

    return StreamBuilder<Set<DateTime>>(
      stream: watchFrozen(
        const NoParams(),
      ).map((either) => either.getOrElse((_) => const <DateTime>{})),
      builder: (context, snap) {
        final frozen = snap.data ?? const <DateTime>{};
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final isTodayFrozen = frozen.contains(today);

        return PopupMenuButton<void>(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.more_horiz_rounded),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          position: PopupMenuPosition.under,
          constraints: const BoxConstraints(minWidth: 240),
          itemBuilder: (context) => [
            // Freeze Today Toggle
            PopupMenuItem<void>(
              onTap: () {
                setFrozen(
                  SetDayFrozenParams(day: today, frozen: !isTodayFrozen),
                );
              },
              child: Row(
                children: [
                  Icon(
                    isTodayFrozen
                        ? Icons.ac_unit_rounded
                        : Icons.ac_unit_outlined,
                    size: 20,
                    color: isTodayFrozen ? AppTheme.frostBlue : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      isTodayFrozen ? 'Unfreeze Today' : 'Freeze Today',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (isTodayFrozen)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.freshGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuItem<void>(
              onTap: () => context.pushNamed(RouteNames.freeze),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  const Text(
                    'Manage Freezes',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            const PopupMenuDivider(),

            PopupMenuItem<void>(
              onTap: () {
                final now = DateTime.now();
                final rangeA = DateTime(now.year, now.month, 1);
                final rangeB = DateTime(now.year, now.month - 1, 1);
                context.pushNamed(
                  RouteNames.historyCompare,
                  queryParameters: {
                    'a': rangeA.toIso8601String(),
                    'b': rangeB.toIso8601String(),
                  },
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Text(
                    'Compare Progress',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            PopupMenuItem<void>(
              onTap: () => context.pushNamed(RouteNames.historyOverview),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: AppTheme.victoryGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.insights_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Text(
                    'Progress Overview',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            const PopupMenuDivider(),

            PopupMenuItem<void>(
              onTap: () => context.pushNamed(RouteNames.settings),
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    l10n.navSettings,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}