import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:shared_preferences/shared_preferences.dart';

/// Weight unit preference used across the app (PRs, log entries,
/// workout descriptions). Stored as 'kg' or 'lb' in SharedPreferences.
enum WeightUnit {
  kg('kg', 'Metric (kg)'),
  lb('lb', 'Imperial (lb)');

  const WeightUnit(this.symbol, this.label);
  final String symbol;
  final String label;
}

/// Persisted app preferences — currently just the weight unit, but
/// the holder is shaped so future toggles (e.g. weekly reports) can
/// ride along without another singleton.
class SettingsService extends ChangeNotifier {
  static const _kUnit = 'weight_unit';
  static const _kNotifications = 'pref_notifications';
  static const _kWeeklyReports = 'pref_weekly_reports';
  static const _kReminderHour = 'pref_reminder_hour';
  static const _kReminderMinute = 'pref_reminder_minute';

  WeightUnit _unit = WeightUnit.kg;
  WeightUnit get unit => _unit;

  bool _notifications = true;
  bool get notifications => _notifications;

  bool _weeklyReports = false;
  bool get weeklyReports => _weeklyReports;

  /// Daily reminder time (local). Defaults to 7:00 PM so the app
  /// nudges users after the typical post-work window.
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay get reminderTime => _reminderTime;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUnit);
    _unit = WeightUnit.values.firstWhere(
      (u) => u.symbol == raw,
      orElse: () => WeightUnit.kg,
    );
    _notifications = prefs.getBool(_kNotifications) ?? true;
    _weeklyReports = prefs.getBool(_kWeeklyReports) ?? false;
    final hour = prefs.getInt(_kReminderHour);
    final minute = prefs.getInt(_kReminderMinute);
    if (hour != null && minute != null) {
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setUnit(WeightUnit unit) async {
    if (_unit == unit) return;
    _unit = unit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUnit, unit.symbol);
  }

  Future<void> setNotifications(bool value) async {
    if (_notifications == value) return;
    _notifications = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifications, value);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    if (_reminderTime.hour == time.hour &&
        _reminderTime.minute == time.minute) {
      return;
    }
    _reminderTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderHour, time.hour);
    await prefs.setInt(_kReminderMinute, time.minute);
  }

  Future<void> setWeeklyReports(bool value) async {
    if (_weeklyReports == value) return;
    _weeklyReports = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWeeklyReports, value);
  }

  /// Convert a stored kg weight to the user's preferred display unit.
  /// Stored weights are always kg; only the display changes.
  double displayWeight(double kg) {
    switch (_unit) {
      case WeightUnit.kg:
        return kg;
      case WeightUnit.lb:
        return kg * 2.2046226218;
    }
  }

  String get unitLabel => _unit.label;
  String get unitSymbol => _unit.symbol;
}
