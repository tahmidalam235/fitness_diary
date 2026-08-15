import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/route_paths.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../responsive/responsive_builder.dart';
import '../responsive/screen_size.dart';
import 'app_drawer.dart';
import 'app_overflow_menu.dart';

/// Top-level destinations in the same order they appear in
/// [AppDrawer]/[AppNavigationRail]. Used by the back-arrow leading
/// widget so it can navigate to the previous destination when the
/// navigator stack is empty (i.e. the user reached the current page via
/// `context.go(...)` rather than `context.push(...)`).
const List<String> _kDrawerRoutes = [
  RoutePaths.today,
  RoutePaths.sessions,
  RoutePaths.workouts,
  RoutePaths.calendar,
  RoutePaths.dashboard,
  RoutePaths.settings,
];

/// App-level scaffold that hosts a permanent Navigation Drawer (compact)
/// or a persistent NavigationRail (medium / expanded) for wider screens.
///
/// On compact widths the scaffold renders a permanent drawer on the
/// leading edge of the body — the drawer is always visible and the AppBar
/// shows no hamburger toggle. On wider widths it switches to a permanent
/// [NavigationRail].
///
/// Opt in with `useNavigationRail: true`. Pages that do not need the rail
/// can simply use the stock Flutter [Scaffold].
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.useNavigationRail = false,
    this.showBackButton = false,
    this.titleLeadingIcon = false,
    this.leading,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  /// Optional leading widget to override the default back button.
  final Widget? leading;

  /// When true, the AppBar's title is prefixed with a small branded app
  /// icon to reinforce product identity on top-level destinations.
  final bool titleLeadingIcon;

  /// When true, the scaffold renders a permanent [AppDrawer] (compact) or
  /// a persistent [NavigationRail] (medium/expanded).
  final bool useNavigationRail;

  /// When true, the AppBar always shows a back-arrow leading widget,
  /// even on top-level routes where `context.canPop()` is false. The
  /// arrow pops the navigator when possible; on a root route it is a
  /// no-op. Opt in for pages where the user is expected to be able to
  /// return to the previous screen (e.g. with a deep link as the entry
  /// point).
  final bool showBackButton;

  /// A prominent, always-tappable back arrow used as the AppBar's
  /// leading widget on every pushed route. Renders nothing on initial
  /// routes so top-level tabs don't show a dead arrow — unless the
  /// page explicitly opts in via [showBackButton].
  Widget? _buildLeading(BuildContext context) {
    if (!context.canPop() && !showBackButton) return null;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => _handleBack(context),
        ),
      ),
    );
  }

  /// Pop the navigator when there is something on the stack (covers
  /// pushed child routes such as `/calendar/day/:date`). Otherwise fall
  /// back to the previous destination in the drawer's route order so
  /// the back arrow always does something meaningful, even on top-level
  /// routes reached via `context.go(...)`.
  void _handleBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final currentPath = GoRouterState.of(context).uri.path;
    final index = _kDrawerRoutes.indexWhere(
      (route) => currentPath.startsWith(route),
    );
    final fallbackIndex = index < 0
        ? 0
        : (index - 1 + _kDrawerRoutes.length) % _kDrawerRoutes.length;
    context.go(_kDrawerRoutes[fallbackIndex]);
  }

  List<Widget> _buildActions(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final isProfile = currentPath.startsWith(RoutePaths.profile);

    return [
      ...?actions,
      if (!isProfile) const _ProfileActionButton(),
      const AppOverflowMenu(),
    ];
  }

  /// AppBar title widget. When [titleLeadingIcon] is true, prepends the
  /// branded app logo (from `assets/logo/`) to the title text.
  Widget _buildTitle(BuildContext context) {
    if (!titleLeadingIcon) return Text(title);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            boxShadow: [
              BoxShadow(
                color: Color(0x406366F1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            'assets/logo/fitness_diary_compact.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _getEffectiveLeading(BuildContext context) {
    if (leading != null) return leading;
    return _buildLeading(context);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLeading = _getEffectiveLeading(context);
    final finalActions = _buildActions(context);

    if (!useNavigationRail) {
      return Scaffold(
        appBar: AppBar(
          title: _buildTitle(context),
          actions: finalActions,
          leading: effectiveLeading,
          automaticallyImplyLeading: effectiveLeading == null,
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      );
    }

    return ResponsiveBuilder(
      builder: (context, size) {
        final rail = const AppNavigationRail();

        if (size.isMediumOrLarger) {
          return Scaffold(
            appBar: AppBar(
              title: _buildTitle(context),
              actions: finalActions,
              leading: effectiveLeading,
              automaticallyImplyLeading: effectiveLeading == null,
            ),
            body: Row(
              children: [
                rail,
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
            floatingActionButton: floatingActionButton,
            bottomNavigationBar: bottomNavigationBar,
          );
        }

        // Compact: on a top-level route we mount the navigation drawer
        // and Material draws the hamburger button automatically. On a
        // pushed child route we drop the drawer entirely and show our
        // prominent back-arrow `leading` instead.
        final canPop = context.canPop();
        return Scaffold(
          appBar: AppBar(
            title: _buildTitle(context),
            actions: finalActions,
            leading: effectiveLeading,
            automaticallyImplyLeading: effectiveLeading == null,
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: body,
          ),
          floatingActionButton: floatingActionButton,
          bottomNavigationBar:
              bottomNavigationBar ??
              (canPop ? null : const _QuickActionsNavBar()),
        );
      },
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        icon: const Icon(Icons.account_circle_outlined),
        onPressed: () => context.pushNamed(RouteNames.profile),
        tooltip: 'Profile',
      ),
    );
  }
}

class _QuickActionsNavBar extends StatelessWidget {
  const _QuickActionsNavBar();

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);

    // Map paths to tab index
    int selectedIndex = 0;
    if (currentPath.startsWith(RoutePaths.today)) {
      selectedIndex = 0;
    } else if (currentPath.startsWith(RoutePaths.calendar)) {
      selectedIndex = 1;
    } else if (currentPath.startsWith(RoutePaths.sessions)) {
      selectedIndex = 2;
    } else if (currentPath.startsWith(RoutePaths.dashboard)) {
      selectedIndex = 3;
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go(RoutePaths.today);
            break;
          case 1:
            context.go(RoutePaths.calendar);
            break;
          case 2:
            context.go(RoutePaths.sessions);
            break;
          case 3:
            context.go(RoutePaths.dashboard);
            break;
        }
      },
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.14),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.2,
          );
        }
        return TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        );
      }),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.play_circle_outline_rounded),
          selectedIcon: Icon(Icons.play_circle_filled_rounded),
          label: 'Today',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Calendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.style_outlined),
          selectedIcon: Icon(Icons.style_rounded),
          label: 'Sessions',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Stats',
        ),
      ],
    );
  }
}
