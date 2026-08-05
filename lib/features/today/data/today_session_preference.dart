import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persists the ordered list of session ids the user picked for "Today"
/// so it survives across re-opens of the Today page and across app
/// launches. The first entry is the currently focused session;
/// additional entries are extra sessions the user added via "Add new
/// session for today's workout".
///
/// Backed by a tiny JSON file in the app's documents directory. We use
/// the file system (not SharedPreferences) to avoid pulling in another
/// dependency for a single key/value pair.
class TodaySessionPreference {
  const TodaySessionPreference();

  static const String _fileName = 'today_session_preference.json';

  /// Reads the persisted picked session ids, in the order they were
  /// picked. Returns an empty list if none is set / the file is
  /// unreadable / the stored value is malformed.
  Future<List<int>> readPickedSessionIds() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const [];
      final value = decoded['pickedSessionIds'];
      if (value is! List) return const [];
      final out = <int>[];
      for (final v in value) {
        if (v is int) out.add(v);
      }
      return out;
    } on Object {
      return const [];
    }
  }

  /// Persists the list of picked session ids (or clears the file when
  /// the list is empty).
  Future<void> writePickedSessionIds(List<int> ids) async {
    try {
      final file = await _file();
      if (ids.isEmpty) {
        if (await file.exists()) {
          await file.delete();
        }
        return;
      }
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({'pickedSessionIds': ids}),
        flush: true,
      );
    } on Object {
      // Best-effort.
    }
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }
}
