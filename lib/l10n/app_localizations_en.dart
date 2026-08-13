// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fitness Diary';

  @override
  String get appTagline => 'Track • Train • Progress';

  @override
  String get navToday => 'Today';

  @override
  String get navSessions => 'Sessions';

  @override
  String get navWorkouts => 'Workout Library';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navSettings => 'Settings';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSave => 'Save';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonErrorTitle => 'Something went wrong';

  @override
  String get commonErrorUnexpected =>
      'An unexpected error occurred. Please try again.';

  @override
  String get todayEmptyTitle => 'No workout started today';

  @override
  String get todayEmptyMessage => 'Select a session to start your workout.';

  @override
  String get todayEmptyAction => 'Select Session';

  @override
  String get todaySelectedLabel => 'Selected';

  @override
  String get todayPickedSessionHeader => 'Today\'s session';

  @override
  String get todayPickAnother => 'Change session';

  @override
  String get sessionsTitle => 'Sessions';

  @override
  String get sessionsEmptyTitle => 'No sessions yet';

  @override
  String get sessionsEmptyMessage =>
      'Create your first workout session to get started.';

  @override
  String get sessionsEmptyAction => 'Create Session';

  @override
  String get sessionsFabNew => 'New Session';

  @override
  String get sessionsSearchHint => 'Search sessions';

  @override
  String get sessionsSearchClear => 'Clear search';

  @override
  String sessionsNoMatchesTitle(String query) {
    return 'No sessions match \"$query\"';
  }

  @override
  String get sessionsNoMatchesMessage =>
      'Try a different search term or create a new session.';

  @override
  String sessionsWorkoutCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
      zero: 'No exercises',
    );
    return '$_temp0';
  }

  @override
  String get sessionFormTitleNew => 'Create Session';

  @override
  String get sessionFormTitleEdit => 'Edit Session';

  @override
  String get sessionFieldName => 'Session name';

  @override
  String get sessionFieldNameHint => 'e.g. Push Day';

  @override
  String get sessionFieldNameRequired => 'Please enter a session name';

  @override
  String get sessionFieldNameTooShort => 'Name must be at least 2 characters';

  @override
  String get sessionFieldNameTooLong => 'Name must be at most 60 characters';

  @override
  String get sessionFieldDescription => 'Description';

  @override
  String get sessionFieldDescriptionHint => 'Optional notes about this session';

  @override
  String get sessionSaveSuccess => 'Session saved';

  @override
  String get sessionDeleteTitle => 'Delete session?';

  @override
  String sessionDeleteMessage(String name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get sessionDetailsTitle => 'Session Details';

  @override
  String get sessionDetailsEditAction => 'Edit Session';

  @override
  String get sessionDetailsDeleteAction => 'Delete Session';

  @override
  String sessionDetailsCreatedAt(String date) {
    return 'Created $date';
  }

  @override
  String sessionDetailsUpdatedAt(String date) {
    return 'Updated $date';
  }

  @override
  String get sessionDetailsPlaceholder =>
      'Exercise management will arrive in the next update.';

  @override
  String get sessionDetailsLoadError => 'Could not load session';

  @override
  String get sessionDetailsNotFound => 'Session not found';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardComingSoon => 'Dashboard insights are coming soon.';

  @override
  String get dashboardGreetingMorning => 'Good morning';

  @override
  String get dashboardGreetingAfternoon => 'Good afternoon';

  @override
  String get dashboardGreetingEvening => 'Good evening';

  @override
  String get dashboardGreetingNight => 'Good night';

  @override
  String get dashboardSubtitle => 'Here\'s where you stand today.';

  @override
  String get dashboardKpiSessionsThisWeek => 'Sessions this week';

  @override
  String get dashboardKpiSessionsThisWeekSub => 'Last 7 days';

  @override
  String get dashboardKpiTotalWorkouts => 'Total workouts logged';

  @override
  String get dashboardKpiTotalWorkoutsSub => 'Across all sessions';

  @override
  String get dashboardKpiSetsLogged => 'Sets logged';

  @override
  String get dashboardKpiSetsLoggedSub => 'All time';

  @override
  String get dashboardQuickActionsTitle => 'Quick actions';

  @override
  String get dashboardActionStartToday => 'Start today\'s workout';

  @override
  String get dashboardActionStartTodaySub => 'Open Today';

  @override
  String get dashboardActionViewCalendar => 'Calendar';

  @override
  String get dashboardActionViewCalendarSub => 'Browse by date';

  @override
  String get dashboardActionBrowseSessions => 'Sessions';

  @override
  String get dashboardActionBrowseSessionsSub => 'All your templates';

  @override
  String get dashboardRecentTitle => 'Recent activity';

  @override
  String get dashboardRecentEmpty =>
      'No workouts yet — your first session will appear here.';

  @override
  String dashboardRecentWorkoutCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '1 workout',
      zero: 'No workouts',
    );
    return '$_temp0';
  }

  @override
  String get dashboardStatSingular => 'workout';

  @override
  String get dashboardStatPlural => 'workouts';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarMonthPrev => 'Previous month';

  @override
  String get calendarMonthNext => 'Next month';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarWeekdaySun => 'Sun';

  @override
  String get calendarWeekdayMon => 'Mon';

  @override
  String get calendarWeekdayTue => 'Tue';

  @override
  String get calendarWeekdayWed => 'Wed';

  @override
  String get calendarWeekdayThu => 'Thu';

  @override
  String get calendarWeekdayFri => 'Fri';

  @override
  String get calendarWeekdaySat => 'Sat';

  @override
  String get calendarLegendCompleted => 'Workout completed';

  @override
  String get calendarEmptyTitle => 'No workouts yet';

  @override
  String get calendarEmptyMessage =>
      'Complete a session to see it appear on your calendar.';

  @override
  String get calendarPickerTitle => 'Pick a month';

  @override
  String get calendarPickerYearPrev => 'Previous year';

  @override
  String get calendarPickerYearNext => 'Next year';

  @override
  String get calendarPickerCancel => 'Cancel';

  @override
  String get calendarPickerConfirm => 'Go';

  @override
  String get dailyDetailsTitle => 'Daily Details';

  @override
  String dailyDetailsDateLabel(String date) {
    return 'Date: $date';
  }

  @override
  String dailyDetailsSessionFallback(int id) {
    return 'Session #$id';
  }

  @override
  String dailyDetailsWorkoutFallback(int id) {
    return 'Exercise #$id';
  }

  @override
  String get dailyDetailsCompletedSets => 'Completed Sets';

  @override
  String get dailyDetailsCompletedReps => 'Reps';

  @override
  String get dailyDetailsWeightUsed => 'Weight';

  @override
  String get dailyDetailsDuration => 'Duration';

  @override
  String get dailyDetailsNotes => 'Notes';

  @override
  String get dailyDetailsEmptyTitle => 'No workout completed on this day';

  @override
  String get dailyDetailsEmptyMessage =>
      'Pick a different date to see your history.';

  @override
  String get dailyDetailsLoadError => 'Could not load this day\'s details';

  @override
  String get dailyDetailsInvalidDate => 'Invalid date';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsComingSoon => 'App settings will appear here.';

  @override
  String get workoutsTitle => 'Workout Library';

  @override
  String get workoutsComingSoon => 'The workout library is coming soon.';

  @override
  String get workoutsSubtitle => 'Browse every exercise across your sessions';

  @override
  String get workoutAddTitle => 'Add Workout';

  @override
  String get workoutEditTitle => 'Edit Workout';

  @override
  String get workoutFieldName => 'Exercise name';

  @override
  String get workoutFieldNameHint => 'e.g. Bench Press';

  @override
  String get workoutFieldNameRequired => 'Please enter an exercise name';

  @override
  String get workoutFieldNameTooShort => 'Name must be at least 2 characters';

  @override
  String get workoutFieldDefaultSets => 'Default sets';

  @override
  String get workoutFieldDefaultReps => 'Default reps';

  @override
  String get workoutFieldDefaultDuration => 'Default duration (minutes)';

  @override
  String get workoutFieldDefaultWeight => 'Default weight';

  @override
  String get workoutFieldTargetedBodyPart => 'Targeted body part';

  @override
  String get workoutTargetedBodyPartEmpty => 'Select body part';

  @override
  String get workoutTargetedBodyPartClear => 'Clear selection';

  @override
  String get workoutFieldNotes => 'Notes';

  @override
  String get workoutFieldNumberRequired => 'Required';

  @override
  String workoutFieldNumberTooSmall(Object min) {
    return 'Must be at least $min';
  }

  @override
  String workoutFieldNumberTooLarge(Object max) {
    return 'Must be at most $max';
  }

  @override
  String get workoutDeleteTitle => 'Delete workout?';

  @override
  String workoutDeleteMessage(String name) {
    return 'Are you sure you want to remove \"$name\" from this session? This action cannot be undone.';
  }

  @override
  String get workoutDetailsTapHint => 'Tap to track today\'s sets';

  @override
  String get workoutListEmptyTitle => 'No workouts yet';

  @override
  String get workoutListEmptyMessage =>
      'Add your first exercise to this session.';

  @override
  String get workoutListEmptyAction => 'Add Workout';

  @override
  String workoutListSetsReps(int sets, int reps) {
    return '$sets sets × $reps reps';
  }

  @override
  String workoutListDuration(int minutes) {
    return '$minutes min';
  }

  @override
  String workoutListWeight(String weight) {
    return '$weight kg';
  }

  @override
  String get workoutActionEdit => 'Edit workout';

  @override
  String get workoutActionDelete => 'Delete workout';

  @override
  String get workoutActionReorder => 'Reorder';

  @override
  String get routerErrorTitle => 'Page not found';

  @override
  String get routerErrorMessage => 'The requested page does not exist.';

  @override
  String get authLoginTitle => 'Welcome back';

  @override
  String get authLoginSubtitle => 'Sign in to continue your journey.';

  @override
  String get authUsername => 'Username';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordRule => 'At least 8 characters';

  @override
  String get authLoginButton => 'Sign In';

  @override
  String get authNoAccount => 'Don\'t have an account? Sign up';

  @override
  String get authSignupTitle => 'Create Account';

  @override
  String get authSignupSubtitle => 'Start tracking your fitness today.';

  @override
  String get authUsernameRule => '3-32 characters';

  @override
  String get authConfirmPassword => 'Confirm Password';

  @override
  String get authDisplayName => 'Display Name';

  @override
  String get authEmail => 'Email Address';

  @override
  String get authSignupButton => 'Create Account';

  @override
  String get authHasAccount => 'Already have an account? Sign in';

  @override
  String get authInvalidCredentials => 'Invalid username or password';

  @override
  String get authUsernameTaken => 'Username is already taken';

  @override
  String get authLogout => 'Log Out';

  @override
  String get authLogoutConfirm => 'Log out?';

  @override
  String get authLogoutConfirmBody =>
      'Are you sure you want to log out of your account?';

  @override
  String get authForgotPassword => 'Forgot Password?';

  @override
  String get authForgotPasswordTitle => 'Reset your password';

  @override
  String get authForgotPasswordBody =>
      'Enter the email address you registered with. We\'ll send a reset link to that account.';

  @override
  String get authForgotPasswordSend => 'Send reset link';

  @override
  String get authForgotPasswordCancel => 'Cancel';

  @override
  String get authForgotPasswordSuccess =>
      'If an account exists for that email, a password-reset link is on its way.';

  @override
  String get authForgotPasswordSuccessWithSpamHint =>
      'If an account exists, a password-reset link is on its way. Check your spam folder if you don\'t see it within a few minutes.';

  @override
  String get authForgotPasswordUserNotFound =>
      'No account is registered with that email.';

  @override
  String get authForgotPasswordInvalidUsername =>
      'Please enter a valid email address.';

  @override
  String get authForgotPasswordGenericError =>
      'Could not send reset link. Please try again.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get historyFreezeTitle => 'Streak Freeze';

  @override
  String get historyFreezeHelp =>
      'Freeze a day to preserve your streak when you can\'t train.';

  @override
  String get historyFreezeEmpty => 'No freezes applied yet.';

  @override
  String get historyCompareTitle => 'Compare Progress';

  @override
  String get historyCompareRangeA => 'First Period';

  @override
  String get historyCompareRangeB => 'Second Period';

  @override
  String get historyPeriodEmpty => 'No data for this period.';
}
