import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// App title shown in the system task switcher and splash.
  ///
  /// In en, this message translates to:
  /// **'Fitness Diary'**
  String get appTitle;

  /// Short marketing line shown on the splash screen.
  ///
  /// In en, this message translates to:
  /// **'Track • Train • Progress'**
  String get appTagline;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get navSessions;

  /// No description provided for @navWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workout Library'**
  String get navWorkouts;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonErrorTitle;

  /// No description provided for @commonErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get commonErrorUnexpected;

  /// No description provided for @todayEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No workout started today'**
  String get todayEmptyTitle;

  /// No description provided for @todayEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a session to start your workout.'**
  String get todayEmptyMessage;

  /// No description provided for @todayEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Select Session'**
  String get todayEmptyAction;

  /// No description provided for @todaySelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get todaySelectedLabel;

  /// No description provided for @todayPickedSessionHeader.
  ///
  /// In en, this message translates to:
  /// **'Today\'s session'**
  String get todayPickedSessionHeader;

  /// No description provided for @todayPickAnother.
  ///
  /// In en, this message translates to:
  /// **'Change session'**
  String get todayPickAnother;

  /// No description provided for @sessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionsTitle;

  /// No description provided for @sessionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get sessionsEmptyTitle;

  /// No description provided for @sessionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first workout session to get started.'**
  String get sessionsEmptyMessage;

  /// No description provided for @sessionsEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Create Session'**
  String get sessionsEmptyAction;

  /// No description provided for @sessionsFabNew.
  ///
  /// In en, this message translates to:
  /// **'New Session'**
  String get sessionsFabNew;

  /// No description provided for @sessionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search sessions'**
  String get sessionsSearchHint;

  /// No description provided for @sessionsSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get sessionsSearchClear;

  /// Title shown when the search query has no matches.
  ///
  /// In en, this message translates to:
  /// **'No sessions match \"{query}\"'**
  String sessionsNoMatchesTitle(String query);

  /// No description provided for @sessionsNoMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or create a new session.'**
  String get sessionsNoMatchesMessage;

  /// Pluralized exercise count shown on session cards.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No exercises} =1{1 exercise} other{{count} exercises}}'**
  String sessionsWorkoutCount(int count);

  /// No description provided for @sessionFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Create Session'**
  String get sessionFormTitleNew;

  /// No description provided for @sessionFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Session'**
  String get sessionFormTitleEdit;

  /// No description provided for @sessionFieldName.
  ///
  /// In en, this message translates to:
  /// **'Session name'**
  String get sessionFieldName;

  /// No description provided for @sessionFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Push Day'**
  String get sessionFieldNameHint;

  /// No description provided for @sessionFieldNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a session name'**
  String get sessionFieldNameRequired;

  /// No description provided for @sessionFieldNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get sessionFieldNameTooShort;

  /// No description provided for @sessionFieldNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name must be at most 60 characters'**
  String get sessionFieldNameTooLong;

  /// No description provided for @sessionFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sessionFieldDescription;

  /// No description provided for @sessionFieldDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes about this session'**
  String get sessionFieldDescriptionHint;

  /// No description provided for @sessionSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Session saved'**
  String get sessionSaveSuccess;

  /// No description provided for @sessionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete session?'**
  String get sessionDeleteTitle;

  /// Confirmation message shown before deleting a session.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String sessionDeleteMessage(String name);

  /// No description provided for @sessionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetailsTitle;

  /// No description provided for @sessionDetailsEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Session'**
  String get sessionDetailsEditAction;

  /// No description provided for @sessionDetailsDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Session'**
  String get sessionDetailsDeleteAction;

  /// No description provided for @sessionDetailsCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String sessionDetailsCreatedAt(String date);

  /// No description provided for @sessionDetailsUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String sessionDetailsUpdatedAt(String date);

  /// No description provided for @sessionDetailsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Exercise management will arrive in the next update.'**
  String get sessionDetailsPlaceholder;

  /// No description provided for @sessionDetailsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load session'**
  String get sessionDetailsLoadError;

  /// No description provided for @sessionDetailsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Session not found'**
  String get sessionDetailsNotFound;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Dashboard insights are coming soon.'**
  String get dashboardComingSoon;

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashboardGreetingMorning;

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashboardGreetingAfternoon;

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get dashboardGreetingEvening;

  /// No description provided for @dashboardGreetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get dashboardGreetingNight;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s where you stand today.'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardKpiSessionsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Sessions this week'**
  String get dashboardKpiSessionsThisWeek;

  /// No description provided for @dashboardKpiSessionsThisWeekSub.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get dashboardKpiSessionsThisWeekSub;

  /// No description provided for @dashboardKpiTotalWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Total workouts logged'**
  String get dashboardKpiTotalWorkouts;

  /// No description provided for @dashboardKpiTotalWorkoutsSub.
  ///
  /// In en, this message translates to:
  /// **'Across all sessions'**
  String get dashboardKpiTotalWorkoutsSub;

  /// No description provided for @dashboardKpiSetsLogged.
  ///
  /// In en, this message translates to:
  /// **'Sets logged'**
  String get dashboardKpiSetsLogged;

  /// No description provided for @dashboardKpiSetsLoggedSub.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get dashboardKpiSetsLoggedSub;

  /// No description provided for @dashboardQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardQuickActionsTitle;

  /// No description provided for @dashboardActionStartToday.
  ///
  /// In en, this message translates to:
  /// **'Start today\'s workout'**
  String get dashboardActionStartToday;

  /// No description provided for @dashboardActionStartTodaySub.
  ///
  /// In en, this message translates to:
  /// **'Open Today'**
  String get dashboardActionStartTodaySub;

  /// No description provided for @dashboardActionViewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get dashboardActionViewCalendar;

  /// No description provided for @dashboardActionViewCalendarSub.
  ///
  /// In en, this message translates to:
  /// **'Browse by date'**
  String get dashboardActionViewCalendarSub;

  /// No description provided for @dashboardActionBrowseSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get dashboardActionBrowseSessions;

  /// No description provided for @dashboardActionBrowseSessionsSub.
  ///
  /// In en, this message translates to:
  /// **'All your templates'**
  String get dashboardActionBrowseSessionsSub;

  /// No description provided for @dashboardRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashboardRecentTitle;

  /// No description provided for @dashboardRecentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet — your first session will appear here.'**
  String get dashboardRecentEmpty;

  /// No description provided for @dashboardRecentWorkoutCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No workouts} =1{1 workout} other{{count} workouts}}'**
  String dashboardRecentWorkoutCount(int count);

  /// No description provided for @dashboardStatSingular.
  ///
  /// In en, this message translates to:
  /// **'workout'**
  String get dashboardStatSingular;

  /// No description provided for @dashboardStatPlural.
  ///
  /// In en, this message translates to:
  /// **'workouts'**
  String get dashboardStatPlural;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarMonthPrev.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarMonthPrev;

  /// No description provided for @calendarMonthNext.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarMonthNext;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get calendarWeekdaySun;

  /// No description provided for @calendarWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get calendarWeekdayMon;

  /// No description provided for @calendarWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get calendarWeekdayTue;

  /// No description provided for @calendarWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get calendarWeekdayWed;

  /// No description provided for @calendarWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get calendarWeekdayThu;

  /// No description provided for @calendarWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get calendarWeekdayFri;

  /// No description provided for @calendarWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get calendarWeekdaySat;

  /// No description provided for @calendarLegendCompleted.
  ///
  /// In en, this message translates to:
  /// **'Workout completed'**
  String get calendarLegendCompleted;

  /// No description provided for @calendarEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get calendarEmptyTitle;

  /// No description provided for @calendarEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete a session to see it appear on your calendar.'**
  String get calendarEmptyMessage;

  /// No description provided for @calendarPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a month'**
  String get calendarPickerTitle;

  /// No description provided for @calendarPickerYearPrev.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get calendarPickerYearPrev;

  /// No description provided for @calendarPickerYearNext.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get calendarPickerYearNext;

  /// No description provided for @calendarPickerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get calendarPickerCancel;

  /// No description provided for @calendarPickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get calendarPickerConfirm;

  /// No description provided for @dailyDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Details'**
  String get dailyDetailsTitle;

  /// No description provided for @dailyDetailsDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dailyDetailsDateLabel(String date);

  /// No description provided for @dailyDetailsSessionFallback.
  ///
  /// In en, this message translates to:
  /// **'Session #{id}'**
  String dailyDetailsSessionFallback(int id);

  /// No description provided for @dailyDetailsWorkoutFallback.
  ///
  /// In en, this message translates to:
  /// **'Exercise #{id}'**
  String dailyDetailsWorkoutFallback(int id);

  /// No description provided for @dailyDetailsCompletedSets.
  ///
  /// In en, this message translates to:
  /// **'Completed Sets'**
  String get dailyDetailsCompletedSets;

  /// No description provided for @dailyDetailsCompletedReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get dailyDetailsCompletedReps;

  /// No description provided for @dailyDetailsWeightUsed.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get dailyDetailsWeightUsed;

  /// No description provided for @dailyDetailsDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get dailyDetailsDuration;

  /// No description provided for @dailyDetailsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get dailyDetailsNotes;

  /// No description provided for @dailyDetailsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No workout completed on this day'**
  String get dailyDetailsEmptyTitle;

  /// No description provided for @dailyDetailsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Pick a different date to see your history.'**
  String get dailyDetailsEmptyMessage;

  /// No description provided for @dailyDetailsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this day\'s details'**
  String get dailyDetailsLoadError;

  /// No description provided for @dailyDetailsInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid date'**
  String get dailyDetailsInvalidDate;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'App settings will appear here.'**
  String get settingsComingSoon;

  /// No description provided for @workoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Library'**
  String get workoutsTitle;

  /// No description provided for @workoutsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'The workout library is coming soon.'**
  String get workoutsComingSoon;

  /// No description provided for @workoutsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse every exercise across your sessions'**
  String get workoutsSubtitle;

  /// No description provided for @workoutAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Workout'**
  String get workoutAddTitle;

  /// No description provided for @workoutEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Workout'**
  String get workoutEditTitle;

  /// No description provided for @workoutFieldName.
  ///
  /// In en, this message translates to:
  /// **'Exercise name'**
  String get workoutFieldName;

  /// No description provided for @workoutFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bench Press'**
  String get workoutFieldNameHint;

  /// No description provided for @workoutFieldNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an exercise name'**
  String get workoutFieldNameRequired;

  /// No description provided for @workoutFieldNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get workoutFieldNameTooShort;

  /// No description provided for @workoutFieldDefaultSets.
  ///
  /// In en, this message translates to:
  /// **'Default sets'**
  String get workoutFieldDefaultSets;

  /// No description provided for @workoutFieldDefaultReps.
  ///
  /// In en, this message translates to:
  /// **'Default reps'**
  String get workoutFieldDefaultReps;

  /// No description provided for @workoutFieldDefaultDuration.
  ///
  /// In en, this message translates to:
  /// **'Default duration (seconds)'**
  String get workoutFieldDefaultDuration;

  /// No description provided for @workoutFieldDefaultWeight.
  ///
  /// In en, this message translates to:
  /// **'Default weight'**
  String get workoutFieldDefaultWeight;

  /// No description provided for @workoutFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get workoutFieldNotes;

  /// No description provided for @workoutFieldNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get workoutFieldNumberRequired;

  /// No description provided for @workoutFieldNumberTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Must be at least {min}'**
  String workoutFieldNumberTooSmall(Object min);

  /// No description provided for @workoutFieldNumberTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Must be at most {max}'**
  String workoutFieldNumberTooLarge(Object max);

  /// No description provided for @workoutDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete workout?'**
  String get workoutDeleteTitle;

  /// No description provided for @workoutDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{name}\" from this session? This action cannot be undone.'**
  String workoutDeleteMessage(String name);

  /// No description provided for @workoutDetailsTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to track today\'s sets'**
  String get workoutDetailsTapHint;

  /// No description provided for @workoutListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get workoutListEmptyTitle;

  /// No description provided for @workoutListEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first exercise to this session.'**
  String get workoutListEmptyMessage;

  /// No description provided for @workoutListEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Add Workout'**
  String get workoutListEmptyAction;

  /// No description provided for @workoutListSetsReps.
  ///
  /// In en, this message translates to:
  /// **'{sets} sets × {reps} reps'**
  String workoutListSetsReps(int sets, int reps);

  /// No description provided for @workoutListDuration.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String workoutListDuration(int seconds);

  /// No description provided for @workoutListWeight.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg'**
  String workoutListWeight(String weight);

  /// No description provided for @workoutActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit workout'**
  String get workoutActionEdit;

  /// No description provided for @workoutActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete workout'**
  String get workoutActionDelete;

  /// No description provided for @workoutActionReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get workoutActionReorder;

  /// No description provided for @routerErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get routerErrorTitle;

  /// No description provided for @routerErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'The requested page does not exist.'**
  String get routerErrorMessage;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey.'**
  String get authLoginSubtitle;

  /// No description provided for @authUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsername;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPasswordRule;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authLoginButton;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get authNoAccount;

  /// No description provided for @authSignupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authSignupTitle;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your fitness today.'**
  String get authSignupSubtitle;

  /// No description provided for @authUsernameRule.
  ///
  /// In en, this message translates to:
  /// **'3-32 characters'**
  String get authUsernameRule;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPassword;

  /// No description provided for @authDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get authDisplayName;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get authEmail;

  /// No description provided for @authSignupButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authSignupButton;

  /// No description provided for @authHasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHasAccount;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get authInvalidCredentials;

  /// No description provided for @authUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username is already taken'**
  String get authUsernameTaken;

  /// No description provided for @authLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get authLogout;

  /// No description provided for @authLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get authLogoutConfirm;

  /// No description provided for @authLogoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get authLogoutConfirmBody;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @historyFreezeTitle.
  ///
  /// In en, this message translates to:
  /// **'Streak Freeze'**
  String get historyFreezeTitle;

  /// No description provided for @historyFreezeHelp.
  ///
  /// In en, this message translates to:
  /// **'Freeze a day to preserve your streak when you can\'t train.'**
  String get historyFreezeHelp;

  /// No description provided for @historyFreezeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No freezes applied yet.'**
  String get historyFreezeEmpty;

  /// No description provided for @historyCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare Progress'**
  String get historyCompareTitle;

  /// No description provided for @historyCompareRangeA.
  ///
  /// In en, this message translates to:
  /// **'First Period'**
  String get historyCompareRangeA;

  /// No description provided for @historyCompareRangeB.
  ///
  /// In en, this message translates to:
  /// **'Second Period'**
  String get historyCompareRangeB;

  /// No description provided for @historyPeriodEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data for this period.'**
  String get historyPeriodEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
