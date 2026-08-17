import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/route_paths.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Primary navigation destinations used by [AppNavigationRail].
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
    final theme = Theme.of(context);

    return NavigationRail(
      extended: extended,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.selected,
      onDestinationSelected: (index) {
        context.go(destinations[index].route);
      },
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.14),
      leading: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40EF4444),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.fitness_center_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.pushNamed(RouteNames.profile),
            tooltip: 'Profile',
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
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