import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../responsive/responsive_builder.dart';
import '../responsive/screen_size.dart';
import 'app_drawer.dart';

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
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

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
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leading = _buildLeading(context);
    if (!useNavigationRail) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: false,
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
              title: Text(title),
              actions: actions,
              leading: leading,
              automaticallyImplyLeading: false,
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
            title: Text(title),
            actions: actions,
            leading: leading,
            automaticallyImplyLeading: false,
          ),
          drawer: canPop ? null : const AppDrawer(),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: body,
          ),
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
        );
      },
    );
  }
}
