import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/route_paths.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Primary navigation destinations used by both [AppDrawer] and
/// [AppNavigationRail].
class _NavDest {
  const _NavDest({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
}

List<_NavDest> _destinationsFor(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return [
    _NavDest(
      icon: Icons.today_outlined,
      selectedIcon: Icons.today_rounded,
      label: l10n.navToday,
      route: RoutePaths.today,
    ),
    _NavDest(
      icon: Icons.view_week_outlined,
      selectedIcon: Icons.view_week_rounded,
      label: l10n.navSessions,
      route: RoutePaths.sessions,
    ),
    _NavDest(
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center_rounded,
      label: l10n.navWorkouts,
      route: RoutePaths.workouts,
    ),
    _NavDest(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: l10n.navCalendar,
      route: RoutePaths.calendar,
    ),
    _NavDest(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      label: l10n.navDashboard,
      route: RoutePaths.dashboard,
    ),
    _NavDest(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: l10n.navSettings,
      route: RoutePaths.settings,
    ),
  ];
}

/// Drawer used in compact layouts. Triggered via the hamburger button.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final destinations = _destinationsFor(context);
    final currentRoute = GoRouterState.of(context).uri.path;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.md),
                      ),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      size: AppIconSize.md,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.appTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                children: [
                  for (final dest in destinations)
                    _NavTile(
                      dest: dest,
                      selected: currentRoute.startsWith(dest.route),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        if (navigator.canPop()) {
                          navigator.pop();
                        }
                        context.go(dest.route);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Persistent rail used in medium / expanded layouts by [AppScaffold].
class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({super.key});

  @override
  Widget build(BuildContext context) {
    final destinations = _destinationsFor(context);
    final currentRoute = GoRouterState.of(context).uri.path;
    final selectedIndex = destinations.indexWhere(
      (d) => currentRoute.startsWith(d.route),
    );
    final extended = MediaQuery.sizeOf(context).width >= 1100;

    return NavigationRail(
      extended: extended,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.selected,
      onDestinationSelected: (index) {
        context.go(destinations[index].route);
      },
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
            boxShadow: [
              BoxShadow(
                color: Color(0x406366F1),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.fitness_center_rounded,
            color: Colors.white,
          ),
        ),
      ),
      destinations: [
        for (final dest in destinations)
          NavigationRailDestination(
            icon: Icon(dest.icon),
            selectedIcon: Icon(dest.selectedIcon),
            label: Text(dest.label),
          ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.dest,
    required this.selected,
    required this.onTap,
  });

  final _NavDest dest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
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
                  selected ? dest.selectedIcon : dest.icon,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    dest.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}