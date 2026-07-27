import 'package:fitness_diary/features/dashboard/presentation/pages/calendar_page.dart';
import 'package:fitness_diary/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fitness_diary/features/session/presentation/pages/sessions_page.dart';
import 'package:fitness_diary/features/settings/presentation/pages/settings_page.dart';
import 'package:fitness_diary/features/splash/presentation/pages/splash_page.dart';
import 'package:fitness_diary/features/today/presentation/pages/today_page.dart';
import 'package:fitness_diary/features/workout/presentation/pages/workouts_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/today', builder: (context, state) => const TodayPage()),
    GoRoute(
      path: '/sessions',
      builder: (context, state) => const SessionsPage(),
    ),
    GoRoute(
      path: '/workouts',
      builder: (context, state) => const WorkoutsPage(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
