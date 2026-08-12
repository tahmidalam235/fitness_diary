// One-shot script to delete every WorkoutLog + its WorkoutLogEntry rows
// whose `performedAt` falls on a given calendar day (in local time).
//
// Uses the Firestore REST API directly so this works under plain
// `dart run` (no Flutter SDK compile, no FFI transforms).
//
// Usage (from project root):
//   dart run tool/delete_day_records.dart            # default: 9 Aug 2026
//   dart run tool/delete_day_records.dart 2026-08-09 # explicit date
//   dart run tool/delete_day_records.dart 2026-08-09 --yes   # skip confirm
//
// Auth: set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON
// file, or pass --token <OAuth access token>.
//
// This is destructive — it permanently deletes documents from Firestore
// under `users/{uid}/workoutLogs` and `users/{uid}/workoutLogEntries`.

import 'dart:convert';
import 'dart:io';

const _projectId = 'YOUR_FIREBASE_PROJECT_ID'; // override via --project
const _baseUrl = 'https://firestore.googleapis.com/v1';

Future<void> main(List<String> args) async {
  final projectId = _projectFromArgs(args) ?? _projectId;
  final token = _tokenFromArgs(args) ?? await _discoverToken();
  if (projectId == 'YOUR_FIREBASE_PROJECT_ID') {
    stderr.writeln('Pass --project <id> (or edit _projectId in the script).');
    exit(2);
  }

  final day = _parseDay(args.isNotEmpty && !args[0].startsWith('--')
      ? args[0]
      : '2026-08-09');
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final startIso = dayStart.toUtc().toIso8601String();
  final endIso = dayEnd.toUtc().toIso8601String();

  // List every user (no admin SDK so we walk users/ by document list).
  final users = await _listUsers(projectId, token);
  if (users.isEmpty) {
    print('No users in project $projectId.');
    return;
  }

  final candidates = <(String, String)>[]; // (uid, logFirestoreId)
  for (final uid in users) {
    final logs = await _runQuery(
      projectId,
      token,
      collectionPath: 'users/$uid/workoutLogs',
      whereClauses: [
        {'field': 'performedAt', 'op': 'GREATER_THAN_OR_EQUAL', 'value': '${dayStart.millisecondsSinceEpoch}'},
        {'field': 'performedAt', 'op': 'LESS_THAN', 'value': '${dayEnd.millisecondsSinceEpoch}'},
      ],
    );
    for (final l in logs) {
      final id = l['document']['name'].toString().split('/').last;
      candidates.add((uid, id));
    }
  }

  if (candidates.isEmpty) {
    print('No logs found for $dayStart — nothing to delete.');
    return;
  }

  print('Will delete ${candidates.length} WorkoutLog(s) for $dayStart:');
  for (final (uid, fid) in candidates) {
    print('  users/$uid/workoutLogs/$fid');
  }

  if (!args.contains('--yes')) {
    stdout.write('Type "delete" to confirm: ');
    final confirm = stdin.readLineSync()?.trim();
    if (confirm != 'delete') {
      print('Aborted.');
      return;
    }
  }

  var logsDeleted = 0;
  var entriesDeleted = 0;
  for (final (uid, logFid) in candidates) {
    final entries = await _runQuery(
      projectId,
      token,
      collectionPath: 'users/$uid/workoutLogEntries',
      whereClauses: [
        {'field': 'workoutLogFirestoreId', 'op': 'EQUAL', 'value': logFid},
      ],
    );
    for (final e in entries) {
      final name = e['document']['name'].toString();
      await _deleteDoc(projectId, token, name);
      entriesDeleted++;
    }
    await _deleteDoc(
      projectId,
      token,
      'projects/$projectId/databases/(default)/documents/users/$uid/workoutLogs/$logFid',
    );
    logsDeleted++;
  }

  print(
    'Done. Deleted $logsDeleted WorkoutLog(s) and '
    '$entriesDeleted WorkoutLogEntry(ies) for $dayStart.',
  );
  // Silence "unused" warning for startIso/endIso if we don't use them.
  assert(startIso.isNotEmpty && endIso.isNotEmpty);
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

DateTime _parseDay(String s) {
  final parts = s.split('-');
  if (parts.length != 3) {
    throw ArgumentError('Expected YYYY-MM-DD, got: $s');
  }
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

Future<List<String>> _listUsers(String projectId, String token) async {
  final url = '$_baseUrl/projects/$projectId/databases/(default)/documents/users?pageSize=200';
  final res = await _get(url, token);
  final body = await _readBody(res);
  if (res.statusCode != 200) {
    stderr.writeln('List users failed: ${res.statusCode} $body');
    return const [];
  }
  final parsed = jsonDecode(body) as Map<String, dynamic>;
  final docs = (parsed['documents'] as List?) ?? const [];
  return [
    for (final d in docs)
      (d['name'] as String).split('/').last,
  ];
}

Future<List<Map<String, dynamic>>> _runQuery(
  String projectId,
  String token, {
  required String collectionPath,
  required List<Map<String, String>> whereClauses,
}) async {
  final url =
      '$_baseUrl/projects/$projectId/databases/(default)/documents:runQuery';
  final structured = <Map<String, dynamic>>[
    for (final c in whereClauses)
      {
        'fieldFilter': {
          'field': {'fieldPath': c['field']},
          'op': c['op'],
          'value': {'integerValue': c['value']},
        },
      },
  ];
  // The REST API only supports a single fieldFilter at the top level
  // (use `compositeFilter` for AND-of-N). Compose here.
  final body = <String, dynamic>{
    'structuredQuery': {
      'from': [{'collectionId': collectionPath.split('/').last}],
      'where': structured.length == 1
          ? structured.first
          : {
              'compositeFilter': {
                'op': 'AND',
                'filters': structured,
              },
            },
      'limit': 200,
    },
  };
  // Firestore REST expects an all-ancestors query for subcollections:
  // add `parent` so it scopes to users/{uid}/workoutLogs etc.
  final parentParts = collectionPath.split('/');
  if (parentParts.length > 1) {
    final parentDoc =
        'projects/$projectId/databases/(default)/documents/${parentParts.take(parentParts.length - 2).join('/')}';
    (body['structuredQuery'] as Map)['parent'] = parentDoc;
  }

  final res = await _postJson(url, token, body);
  final responseBody = await _readBody(res);
  if (res.statusCode != 200) {
    stderr.writeln('Query $collectionPath failed: ${res.statusCode} $responseBody');
    return const [];
  }
  final raw = jsonDecode(responseBody) as List;
  return [
    for (final entry in raw.cast<Map<String, dynamic>>())
      if (entry['document'] != null) entry,
  ];
}

Future<void> _deleteDoc(
  String projectId,
  String token,
  String documentPath,
) async {
  // documentPath may already be fully qualified ("projects/.../documents/...")
  // or relative. Normalise to a full REST URL.
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

Future<HttpClientResponse> _postJson(
  String url,
  String token,
  Object body,
) async {
  final client = HttpClient();
  final req = await client.postUrl(Uri.parse(url));
  req.headers.set('Authorization', 'Bearer $token');
  req.headers.contentType = ContentType.json;
  req.add(utf8.encode(jsonEncode(body)));
  return req.close();
}

Future<HttpClientResponse> _delete(String url, String token) async {
  final client = HttpClient();
  final req = await client.deleteUrl(Uri.parse(url));
  req.headers.set('Authorization', 'Bearer $token');
  return req.close();
}
