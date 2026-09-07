import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks when the user last opened the Suggestions page.
///
/// "New" suggestions are defined as: any workout whose most recent
/// `performedAt` is **strictly after** the last viewed timestamp. When
/// the user has never opened the page, every suggestion is considered
/// new (so the red dot shows on first availability).
///
/// Persistence is local (SharedPreferences) so the marker survives
/// app restarts.
class SuggestionsReadService extends ChangeNotifier {
  SuggestionsReadService();

  static const _kLastViewedAtMs = 'suggestions_last_viewed_at_ms';

  DateTime? _lastViewedAt;
  DateTime? get lastViewedAt => _lastViewedAt;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastViewedAtMs);
    _lastViewedAt = ms != null
        ? DateTime.fromMillisecondsSinceEpoch(ms)
        : null;
    _loaded = true;
    notifyListeners();
  }

  /// True when at least one suggestion whose `lastPerformed` is after
  /// [lastViewedAt] exists. Called by the overflow menu's red dot.
  bool hasUnread(List<DateTime> lastPerformeds) {
    final cutoff = _lastViewedAt;
    if (cutoff == null) {
      return lastPerformeds.isNotEmpty;
    }
    return lastPerformeds.any((d) => d.isAfter(cutoff));
  }

  /// Mark the suggestions as viewed "now". Called when the user opens
  /// the Suggestions page so the menu's red dot clears.
  Future<void> markViewed() async {
    final now = DateTime.now();
    if (_lastViewedAt != null && !now.isAfter(_lastViewedAt!)) return;
    _lastViewedAt = now;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastViewedAtMs, now.millisecondsSinceEpoch);
  }

  /// Wipes the local key. Best-effort — used by logout flows if/when
  /// the app adds one.
  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLastViewedAtMs);
      _lastViewedAt = null;
      notifyListeners();
    } catch (_) {
      // best-effort
    }
  }
}
