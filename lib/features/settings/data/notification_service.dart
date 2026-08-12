import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps [FlutterLocalNotificationsPlugin] for the single use case we
/// care about: scheduling a daily local reminder that nudges the user
/// to start a workout. No remote / push backend — purely on-device.
class NotificationService {
  static const _channelId = 'workout_reminders';
  static const _channelName = 'Workout reminders';
  static const _channelDesc = 'Daily nudge to log your workout session.';
  static const _dailyReminderId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Sets up the plugin + the timezone database. Idempotent — safe
  /// to call multiple times. Must be awaited once during DI bootstrap
  /// so the first reminder schedules successfully.
  Future<void> init() async {
    if (_initialized) return;

    // timezone is required for zonedSchedule — without it the OS
    // rejects the alarm because it can't resolve the wall-clock time.
    tz_data.initializeTimeZones();

    // Critical: tz.local defaults to UTC, which means scheduled
    // alarms fire at UTC times and show up at the wrong wall-clock
    // hour on the device. Read the IANA name from the OS and switch
    // tz.local to that zone before scheduling anything.
    await _updateLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    // Initialize with a callback to ensure the plugin handles responses
    // even if we don't do anything with them yet.
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (kDebugMode) {
          debugPrint('[NotificationService] tapped: ${details.payload}');
        }
      },
    );

    // Android 8+ requires a channel to be created before any
    // notification posts. Creating it eagerly means the very first
    // scheduled notification lands in a labeled, user-mutable bucket.
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  /// Asks the OS for notification permission. Returns true if the
  /// user granted (or already had) permission; false otherwise.
  /// Safe to call on every toggle — the OS will no-op if already
  /// resolved.
  Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted == false) return false;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      if (granted == false) return false;

      // Android 12+ — exact alarms need their own permission. The
      // plugin's `requestExactAlarmsPermission` opens the system
      // settings screen; the user has to flip the toggle manually
      // for "Alarms & reminders". We call it once and proceed even
      // if it's denied — scheduleDaily() will fall back to inexact.
      await android.requestExactAlarmsPermission();
    }

    return true;
  }

  /// Whether the OS currently allows exact-time alarms. False means
  /// notifications will still fire but within a system-defined window
  /// around the scheduled time (typically ±15 minutes).
  Future<bool> canScheduleExact() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    final can = await android.canScheduleExactNotifications();
    return can ?? true;
  }

  /// Schedules (or re-schedules) the daily reminder. Cancels any
  /// previously scheduled one first so we never end up with two
  /// stacked alarms after the user changes the time.
  ///
  /// On Android 12+, exact alarms require SCHEDULE_EXACT_ALARM to be
  /// granted. We try for the exact alarm first; if it's not granted,
  /// we fall back to an inexact alarm so the notification still fires
  /// (within a system-defined window, usually a few minutes around the
  /// scheduled time).
  Future<void> scheduleDaily(TimeOfDay time) async {
    try {
      if (!_initialized) await init();
      await cancelDaily();

      // Ensure timezone is up-to-date before scheduling.
      await _updateLocalTimezone();

      final next = _nextInstanceOf(time.hour, time.minute);

      final scheduleMode = await _resolveScheduleMode();

      await _plugin.zonedSchedule(
        _dailyReminderId,
        'Time to train',
        "Don't break your streak — log today's workout.",
        next,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
            showWhen: true,
            // Status-bar (small) icon — a monochrome silhouette of the
            // Fitness Diary dumbbell brand mark. Android renders it as
            // white-on-transparent in the status bar; without an
            // explicit `icon` it falls back to the launcher mipmap,
            // which on Android 5+ becomes a white square when the
            // launcher icon isn't monochrome.
            icon: '@drawable/ic_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      if (kDebugMode) {
        debugPrint(
          '[NotificationService] scheduled daily at '
          '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')} '
          '(next: $next, mode: $scheduleMode, zone: ${tz.local.name})',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] schedule error: $e');
      }
    }
  }

  /// Reads the IANA name from the OS and switches tz.local to that
  /// zone. Defaults to UTC if detection fails.
  Future<void> _updateLocalTimezone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationService] failed to resolve local timezone: $e',
        );
      }
    }
  }

  /// Returns the right [AndroidScheduleMode] given current OS
  /// permissions. On Android 12+ the exact-alarm permission is
  /// separate from notification permission; if it's missing the OS
  /// silently drops the alarm. We fall back to inexact so the
  /// notification still fires.
  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl == null) {
      // iOS / desktop — schedule mode is ignored.
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    final canExact = await androidImpl.canScheduleExactNotifications();
    return canExact == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Cancels the daily reminder. Called both when the user disables
  /// the toggle and before scheduling a new one.
  Future<void> cancelDaily() async {
    await _plugin.cancel(_dailyReminderId);
  }

  /// Schedules a one-off notification immediately.
  /// Used to verify that permissions and channels are correctly set up.
  Future<void> sendTestNotification() async {
    if (!_initialized) await init();

    // Ensure we have permission before trying to show a notification.
    final granted = await requestPermission();
    if (!granted) {
      if (kDebugMode) {
        debugPrint('[NotificationService] test failed: permission denied');
      }
      return;
    }

    // We use .show() for an immediate test notification instead of
    // .zonedSchedule() to bypass any timezone/exact-alarm issues
    // during the diagnostic check.
    await _plugin.show(
      999,
      'Test notification',
      'The notification system is working correctly!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          fullScreenIntent: false,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
    );

    if (kDebugMode) {
      debugPrint('[NotificationService] test notification sent');
    }
  }

  /// Returns the next future [tz.TZDateTime] matching the given
  /// hour/minute in the device's local timezone. If today's slot
  /// has already passed, jumps to tomorrow.
  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Returns the list of currently-pending scheduled notifications.
  /// Useful for debugging — the OS keeps the canonical list, not us.
  Future<List<PendingNotificationRequest>> pending() {
    return _plugin.pendingNotificationRequests();
  }

  /// Returns the name of the resolved local timezone (e.g. "Asia/Dhaka").
  /// Exposed so the UI can show "Scheduled in Asia/Dhaka" as a hint.
  String get resolvedTimezoneName => tz.local.name;
}
