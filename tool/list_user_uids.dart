// One-shot helper that lists every Firebase Auth uid known to the
// project. The output is a list of doc ids under `users/`, which is
// exactly the uid used by the app.
//
// Usage (from project root):
//   dart run tool/list_user_uids.dart

import 'dart:convert';
import 'dart:io';

const _projectId = 'fitness-diary-335e1';
const _baseUrl = 'https://firestore.googleapis.com/v1';

Future<void> main(List<String> args) async {
  final projectId = _projectFromArgs(args) ?? _projectId;
  final token = _tokenFromArgs(args) ?? await _discoverToken();

  final url =
      '$_baseUrl/projects/$projectId/databases/(default)/documents/users?pageSize=200';
  final res = await _get(url, token);
  final body = await _readBody(res);
  if (res.statusCode != 200) {
    stderr.writeln('List users failed: ${res.statusCode} $body');
    exit(2);
  }
  final parsed = jsonDecode(body) as Map<String, dynamic>;
  final docs = (parsed['documents'] as List?) ?? const [];
  for (final d in docs) {
    final name = (d['name'] as String).split('/').last;
    print(name);
  }
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
    'No auth token. Pass --token <access token> or set FIRESTORE_TOKEN.',
  );
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