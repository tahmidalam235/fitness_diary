import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/routes/route_paths.dart';

/// Slide-in side drawer that hosts the dashboard's quick actions.
///
/// Triggered from the dashboard's title row (three-line bar at top-left).
/// Lives at the page level — independent of the app-wide primary
/// navigation drawer so it can show its own curated list of shortcuts.
class DashboardQuickActionsDrawer extends StatelessWidget {
  const DashboardQuickActionsDrawer({super.key});

  /// Convenience helper to show the drawer with a Material slide
  /// transition. Returns when the user dismisses it (scrim tap or
  /// action tap).
  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Quick actions',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) {
        return const DashboardQuickActionsDrawer();
      },
      transitionBuilder: (_, animation, _, child) {
        final slide =
            Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return SlideTransition(position: slide, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.bolt_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.dashboardQuickActionsTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.md),
                  _QuickActionTile(
                    icon: Icons.play_circle_filled_rounded,
                    title: l10n.dashboardActionStartToday,
                    sub: l10n.dashboardActionStartTodaySub,
                    accent: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.of(context).pop();
                      // Push so the back arrow returns to the dashboard,
                      // not to whichever tab happened to be on top.
                      context.pushNamed(RouteNames.today);
                    },
                  ),
                  const Gap(AppSpacing.sm),
                  _QuickActionTile(
                    icon: Icons.calendar_month_rounded,
                    title: l10n.dashboardActionViewCalendar,
                    sub: l10n.dashboardActionViewCalendarSub,
                    accent: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.pushNamed(RouteNames.calendar);
                    },
                  ),
                  const Gap(AppSpacing.sm),
                  _QuickActionTile(
                    icon: Icons.style_rounded,
                    title: l10n.dashboardActionBrowseSessions,
                    sub: l10n.dashboardActionBrowseSessionsSub,
                    accent: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.pushNamed(RouteNames.sessions);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.sub,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String sub;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent, size: 22),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(AppSpacing.xxs),
                    Text(
                      sub,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
