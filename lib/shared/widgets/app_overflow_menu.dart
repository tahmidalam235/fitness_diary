import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/routes/route_paths.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
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
          icon: const Icon(Icons.more_vert_rounded),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          position: PopupMenuPosition.under,
          constraints: const BoxConstraints(minWidth: 220),
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
                    color: isTodayFrozen ? const Color(0xFF60A5FA) : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      isTodayFrozen ? 'Unfreeze Today' : 'Freeze Today',
                    ),
                  ),
                  if (isTodayFrozen)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Colors.green,
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
                  const Text('Manage Freezes'),
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
                  const Icon(
                    Icons.compare_arrows_rounded,
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Text('Compare Progress'),
                ],
              ),
            ),
            PopupMenuItem<void>(
              onTap: () => context.pushNamed(RouteNames.historyOverview),
              child: Row(
                children: [
                  const Icon(
                    Icons.insights_rounded,
                    size: 20,
                    color: Colors.deepPurpleAccent,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Text('Progress Overview'),
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
                  Text(l10n.navSettings),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
