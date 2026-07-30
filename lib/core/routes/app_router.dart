import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/calendar/presentation/pages/daily_details_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/session/presentation/pages/session_details_page.dart';
import '../../features/session/presentation/pages/session_form_page.dart';
import '../../features/session/presentation/pages/sessions_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/today/presentation/pages/today_page.dart';
import '../../features/workout/presentation/pages/workout_form_page.dart';
import '../../features/workout/presentation/pages/workouts_page.dart';
import '../../features/workout_log/presentation/pages/workout_tracking_page.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_loading_indicator.dart';
import 'route_paths.dart';

/// Application router. All navigation should go through named routes.
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: RoutePaths.splash,
      name: RouteNames.splash,
      builder: (_, _) => const SplashPage(),
    ),
    GoRoute(
      path: RoutePaths.today,
      name: RouteNames.today,
      builder: (_, state) {
        final sessionIdRaw = state.uri.queryParameters['sessionId'];
        return TodayPage(
          initialSessionId: int.tryParse(sessionIdRaw ?? ''),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.sessions,
      name: RouteNames.sessions,
      builder: (_, _) => const SessionsPage(),
      routes: [
        GoRoute(
          path: RoutePaths.sessionNew,
          name: RouteNames.sessionNew,
          builder: (_, _) => const SessionFormPage(),
        ),
        GoRoute(
          path: RoutePaths.sessionDetails,
          name: RouteNames.sessionDetails,
          builder: (_, state) => SessionDetailsPage(
            sessionId: int.parse(
              state.pathParameters['id']!,
            ),
            autoEnterSelectMode:
                state.uri.queryParameters['select'] == '1',
          ),
          routes: [
            GoRoute(
              path: RoutePaths.sessionEdit,
              name: RouteNames.sessionEdit,
              builder: (_, state) => SessionFormPage(
                sessionId: int.parse(
                  state.pathParameters['id']!,
                ),
              ),
            ),
            GoRoute(
              path: RoutePaths.workoutNew,
              name: RouteNames.workoutNew,
              builder: (_, state) => WorkoutFormPage(
                sessionId: int.parse(state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: RoutePaths.workoutEdit,
              name: RouteNames.workoutEdit,
              builder: (_, state) => WorkoutFormPage(
                sessionId: int.parse(state.pathParameters['id']!),
                workoutId:
                    int.parse(state.pathParameters['workoutId']!),
              ),
            ),
            GoRoute(
              path: RoutePaths.workoutTracking,
              name: RouteNames.workoutTracking,
              builder: (_, state) => WorkoutTrackingPage(
                sessionId: int.parse(state.pathParameters['id']!),
                workoutId:
                    int.parse(state.pathParameters['workoutId']!),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.workouts,
      name: RouteNames.workouts,
      builder: (_, _) => const WorkoutsPage(),
    ),
    GoRoute(
      path: RoutePaths.calendar,
      name: RouteNames.calendar,
      builder: (_, _) => const CalendarPage(),
      routes: [
        GoRoute(
          path: RoutePaths.calendarDay,
          name: RouteNames.calendarDay,
          builder: (_, state) {
            final raw = state.pathParameters['date'] ?? '';
            final parsed = parseDayParam(raw);
            return DailyDetailsPage(
              date: parsed ?? DateTime.now(),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.dashboard,
      name: RouteNames.dashboard,
      builder: (_, _) => const DashboardPage(),
    ),
    GoRoute(
      path: RoutePaths.settings,
      name: RouteNames.settings,
      builder: (_, _) => const SettingsPage(),
    ),
  ],
  errorBuilder: (context, state) => _RouterErrorPage(error: state.error),
);

class _RouterErrorPage extends StatelessWidget {
  const _RouterErrorPage({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canPop = context.canPop();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routerErrorTitle),
        leading: canPop
            ? Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                  ),
                ),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoadingIndicator(),
              const SizedBox(height: 16),
              Text(l10n.routerErrorMessage),
            ],
          ),
        ),
      ),
    );
  }
}
