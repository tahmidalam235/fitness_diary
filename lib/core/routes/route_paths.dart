/// Centralized route path constants.
///
/// Use these whenever you need a raw path (e.g. `context.go(...)`),
/// and prefer `context.goNamed(...)` for navigation by intent.
class RoutePaths {
  const RoutePaths._();

  static const String splash = '/';
  static const String today = '/today';

  // Sessions feature
  static const String sessions = '/sessions';
  static const String sessionNew = 'new';
  static const String sessionDetails = ':id';
  static const String sessionEdit = 'edit';

  // Workouts nested under a session
  static const String workoutNew = 'workouts/new';
  static const String workoutEdit = 'workouts/:workoutId/edit';
  static const String workoutTracking = 'workouts/:workoutId/track';

  // Placeholder features (kept for routing consistency)
  static const String workouts = '/workouts';
  static const String calendar = '/calendar';
  static const String calendarDay = 'day/:date';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
}

/// Named-route identifiers used with `context.goNamed(...)`.
class RouteNames {
  const RouteNames._();

  static const String splash = 'splash';
  static const String today = 'today';
  static const String sessions = 'sessions';
  static const String sessionNew = 'sessionNew';
  static const String sessionDetails = 'sessionDetails';
  static const String sessionEdit = 'sessionEdit';
  static const String workoutNew = 'workoutNew';
  static const String workoutEdit = 'workoutEdit';
  static const String workoutTracking = 'workoutTracking';
  static const String workouts = 'workouts';
  static const String calendar = 'calendar';
  static const String calendarDay = 'calendarDay';
  static const String dashboard = 'dashboard';
  static const String settings = 'settings';
}
