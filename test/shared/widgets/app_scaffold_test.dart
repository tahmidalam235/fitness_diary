import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_diary/shared/widgets/app_scaffold.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/parent/child',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const _ScaffoldShell(title: 'Home'),
      ),
      GoRoute(
        path: '/parent',
        builder: (_, _) => const _ScaffoldShell(title: 'Parent'),
        routes: [
          GoRoute(
            path: 'child',
            builder: (_, _) => const _ScaffoldShell(title: 'Child'),
          ),
        ],
      ),
    ],
  );
}

class _ScaffoldShell extends StatelessWidget {
  const _ScaffoldShell({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: Text('body of $title'),
    );
  }
}

void main() {
  group('AppScaffold back button', () {
    testWidgets('back button appears when GoRouter canPop returns true',
        (tester) async {
      final router = _router();
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      // On /parent/child (pushed via initialLocation), canPop is true.
      expect(find.byTooltip('Back'), findsOneWidget);
    });

    testWidgets('tapping the back button pops the route', (tester) async {
      final router = _router();
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path,
          '/parent/child');

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/parent');
    });
  });
}