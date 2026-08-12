import 'package:flutter/foundation.dart';

/// Coarse-grained sync state used for logging and (optionally) UI hints.
///
/// Per the plan: "no UI redesign is required" — this is exposed mainly
/// for debug / future use. We surface it via [SyncStatusController] so
/// any widget that wants to read the current state can do so without a
/// Stream subscription.
enum SyncStatus {
  /// Nothing has happened yet (e.g. cold start, pre-login).
  idle,

  /// An upload or download is currently in flight.
  syncing,

  /// Last sync operation completed successfully.
  synced,

  /// No network connectivity. The next successful sync will move out
  /// of this state.
  offline,

  /// Last sync operation errored. The next successful sync will move
  /// out of this state. Detailed errors are still logged to debugPrint
  /// but never surfaced to the user.
  failed,
}

/// In-memory broadcast of the current [SyncStatus]. UI listeners
/// (none required by the plan, but exposed for future use) can attach
/// via [addListener].
class SyncStatusController extends ChangeNotifier {
  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastChangedAt;
  String? _lastMessage;

  SyncStatus get status => _status;
  DateTime? get lastChangedAt => _lastChangedAt;
  String? get lastMessage => _lastMessage;

  /// Updates the current status. Safe to call from anywhere.
  void set(SyncStatus next, {String? message}) {
    if (_status == next && _lastMessage == message) return;
    _status = next;
    _lastChangedAt = DateTime.now();
    _lastMessage = message;
    notifyListeners();
  }
}
