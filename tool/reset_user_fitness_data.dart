// One-shot script to delete every user-generated fitness data document
// for the current account — sessions, master workouts, session-workout
// join rows, workout logs, workout log entries, and streak-freeze
// markers.
//
// IMPORTANT: this script does NOT touch the Firebase Auth account, the
// user's profile, or app settings. It only wipes the fitness-tracking
// subcollections under `users/{uid}/`:
//
//   sessions          → SessionModel rows
//   workouts          → master WorkoutModel catalog rows
//   sessionWorkouts   → per-session WorkoutModel join rows
//   workoutLogs       → WorkoutLogModel rows
//   workoutLogEntries → WorkoutLogEntryModel rows
//   freezes           → FreezeDayModel rows
//
// Auth: set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON
// file, or pass --token <OAuth access token>.
//
// Usage (from project root):
//   dart run tool/reset_user_fitness_data.dart --uid <firebase-uid> --yes
//   dart run tool/reset_user_fitness_data.dart --uid <firebase-uid> --token <token> --yes

import 'dart:convert';
import 'dart:io';

const _projectId = 'fitness-diary-335e1';
const _baseUrl = 'https://firestore.googleapis.com/v1';

/// Subcollections to wipe. Order doesn't matter — the REST API doesn't
/// enforce referential integrity, so we just delete each doc by id.
const _subcollectionsToWipe = <String>[
  'sessions',
  'workouts',
  'sessionWorkouts',
  'workoutLogs',
  'workoutLogEntries',
  'freezes',
];

Future<void> main(List<String> args) async {
  final uid = _uidFromArgs(args);
  if (uid == null) {
    stderr.writeln('Missing --uid <firebase-uid>.');
    stderr.writeln(
      'Find your uid by opening Firebase Auth in the console, or by '
      'reading the `users/<uid>` Firestore doc id for your account.',
    );
    exit(2);
  }

  final projectId = _projectFromArgs(args) ?? _projectId;
  final token = _tokenFromArgs(args) ?? await _discoverToken();

  if (!args.contains('--yes')) {
    print(
      'This will permanently delete every doc under the following '
      'subcollections for user $uid in project $projectId:',
    );
    for (final sub in _subcollectionsToWipe) {
      print('  users/$uid/$sub');
    }
    stdout.write('Type "reset" to confirm: ');
    final confirm = stdin.readLineSync()?.trim();
    if (confirm != 'reset') {
      print('Aborted.');
      return;
    }
  }

  var totalDeleted = 0;
  for (final sub in _subcollectionsToWipe) {
    final deleted = await _wipeSubcollection(projectId, token, uid, sub);
    print('Deleted $deleted doc(s) from users/$uid/$sub');
    totalDeleted += deleted;
  }

  print('Done. Total docs deleted: $totalDeleted.');
}

String? _uidFromArgs(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--uid' && i + 1 < args.length) return args[i + 1];
  }
  return null;
}

String? _projectFromArgs(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--project' && i + 1 < args.length) return args[i + 1];
  }
  return null;
}

String? _tokenFromArgs(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--token' && i + 1 < args.length) return args[i + 1];
  }
  return null;
}

Future<String> _discoverToken() async {
  // gcloud auth print-access-token output
  try {
    final res = await Process.run(
      'gcloud',
      ['auth', 'print-access-token'],
      runInShell: true,
    );
    if (res.exitCode == 0) {
      final t = (res.stdout as String).trim();
      if (t.isNotEmpty) return t;
    }
  } catch (_) {}
  final env = Platform.environment['FIRESTORE_TOKEN'];
  if (env != null && env.isNotEmpty) return env;
  throw StateError(
    'No auth token. Pass --token <access token> or set FIRESTORE_TOKEN, '
    'or install gcloud and run `gcloud auth login`.',
  );
}

Future<int> _wipeSubcollection(
  String projectId,
  String token,
  String uid,
  String subcollection,
) async {
  var totalDeleted = 0;
  String? pageToken;
  do {
    final url =
        '$_baseUrl/projects/$projectId/databases/(default)/documents/users/$uid/$subcollection?pageSize=200'
        '${pageToken == null ? '' : '&pageToken=$pageToken'}';
    final res = await _get(url, token);
    final body = await _readBody(res);
    if (res.statusCode != 200) {
      stderr.writeln(
        'List $subcollection failed: ${res.statusCode} $body',
      );
      return totalDeleted;
    }
    final parsed = jsonDecode(body) as Map<String, dynamic>;
    final docs = (parsed['documents'] as List?) ?? const [];
    pageToken = parsed['nextPageToken'] as String?;

    for (final d in docs) {
      final name = d['name'] as String;
      await _deleteDoc(projectId, token, name);
      totalDeleted++;
    }
  } while (pageToken != null);
  return totalDeleted;
}

Future<void> _deleteDoc(
  String projectId,
  String token,
  String documentPath,
) async {
  String fullPath = documentPath;
  if (!fullPath.startsWith('projects/')) {
    fullPath = 'projects/$projectId/databases/(default)/documents/$fullPath';
  }
  final url = '$_baseUrl/$fullPath';
  final res = await _delete(url, token);
  if (res.statusCode != 200) {
    final body = await _readBody(res);
    stderr.writeln('Delete $fullPath failed: ${res.statusCode} $body');
  }
}

Future<String> _readBody(HttpClientResponse res) async {
  return res.transform(utf8.decoder).join();
}

Future<HttpClientResponse> _get(String url, String token) async {
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse(url));
  req.headers.set('Authorization', 'Bearer $token');
  return req.close();
}

Future<HttpClientResponse> _delete(String url, String token) async {
  final client = HttpClient();
  final req = await client.deleteUrl(Uri.parse(url));
  req.headers.set('Authorization', 'Bearer $token');
  return req.close();
}