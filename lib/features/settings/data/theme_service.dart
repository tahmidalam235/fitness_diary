import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app theme mode. Default = [ThemeMode.system] so the app
/// follows the device's light/dark preference on first launch; once
/// the user toggles it, that explicit choice wins across launches.
class ThemeService extends ChangeNotifier {
  static const _kThemeMode = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kThemeMode);
    _mode = _decode(raw);
    _loaded = true;
    notifyListeners();
  }

  /// Updates the theme mode and persists the choice. Listeners (the
  /// root `MaterialApp`) rebuild and switch palettes everywhere.
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, _encode(mode));
  }

  /// Convenience helper for booleans (true = dark, false = light).
  /// `null` (system) is treated as light by this helper.
  Future<void> setDark(bool isDark) {
    return setMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  bool get isDark {
    switch (_mode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
      case ThemeMode.system:
        return false;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _decode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
