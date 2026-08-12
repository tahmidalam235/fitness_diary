import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../core/error/exceptions.dart';
import '../../session/data/datasources/session_local_datasource.dart';
import '../../workout/data/datasources/workout_local_datasource.dart';
import '../../workout_log/data/models/workout_log_entry_model.dart';

/// Service that exports the user's workout history as a CSV file and
/// hands it to the OS share sheet.
///
/// CSV format follows the RFC 4180 quoting rules: any field containing
/// `,`, `"`, or `\n` is wrapped in double quotes and internal quotes
/// are doubled. We hand-roll the writer (~20 lines) instead of pulling
/// in the `csv` package because the export shape is tiny and the only
/// field that routinely needs escaping is the optional `notes`.
class HistoryExportService {
  HistoryExportService({
    required this.workoutLogDao,
    required this.workoutLocalDataSource,
    required this.sessionLocalDataSource,
  });

  final WorkoutLogDao workoutLogDao;
  final WorkoutLocalDataSource workoutLocalDataSource;
  final SessionLocalDataSource sessionLocalDataSource;

  /// CSV column header. Public so tests can reference the canonical
  /// column order.
  static const List<String> csvHeader = [
    'date',
    'time',
    'session',
    'exercise',
    'sets',
    'reps',
    'weight_kg',
    'duration_seconds',
    'notes',
  ];

  /// Builds the full CSV for every workout log in the database (or
  /// every log since [since]) and writes it to
  /// `<docs>/exports/fitness_diary_<timestamp>.csv`. Returns the
  /// resulting [File].
  ///
  /// Throws an [UnexpectedException] if the documents directory can't
  /// be reached; callers should catch and surface a snackbar.
  Future<File> writeCsv({DateTime? since}) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(docs.path, 'exports'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File(p.join(exportDir.path, 'fitness_diary_$stamp.csv'));

      final csv = await buildCsvString(since: since);
      await file.writeAsString(csv, flush: true);
      return file;
    } catch (error) {
      throw UnexpectedException('Failed to write CSV export', cause: error);
    }
  }

  /// Opens the OS share sheet pointing at [file].
  ///
  /// Errors (e.g. user dismissal, unsupported platform) are swallowed
  /// silently: the file is already on disk so the user can still
  /// retrieve it.
  static Future<void> share(
    File file, {
    String subject = 'Fitness Diary export',
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
        text: 'My Fitness Diary progress export.',
      );
    } catch (_) {
      // Intentional: share sheet dismissal / platform no-op.
    }
  }

  /// Returns the CSV body as a string. Public so tests can verify the
  /// encoding without touching the filesystem.
  Future<String> buildCsvString({DateTime? since}) async {
    final allLogs = await workoutLogDao.watchAllLogs().first;
    final filtered = since == null
        ? allLogs
        : allLogs.where((l) => !l.performedAt.isBefore(since)).toList();

    // Sort ascending by performedAt so the file reads chronologically.
    final sorted = [...filtered]
      ..sort((a, b) => a.performedAt.compareTo(b.performedAt));

    // Resolve every distinct sessionId once via the session data
    // source.
    final sessionIds = sorted
        .map((l) => l.sessionId)
        .whereType<int>()
        .toSet()
        .toList();
    final sessionNames = <int, String>{};
    if (sessionIds.isNotEmpty) {
      final allSessions = await sessionLocalDataSource.getAll();
      final wanted = sessionIds.toSet();
      for (final s in allSessions) {
        if (s.id != null && wanted.contains(s.id)) {
          sessionNames[s.id!] = s.name;
        }
      }
    }

    // Fan out to fetch entries per log.
    final workoutFids = <String>{};
    final logToEntries = <String, List<WorkoutLogEntryModel>>{};
    for (final log in sorted) {
      if (log.firestoreId == null) continue;
      final entries = await workoutLogDao
          .watchEntriesForLog(log.firestoreId!)
          .first;
      logToEntries[log.firestoreId!] = entries;
      for (final e in entries) {
        if (e.workoutFirestoreId != null) {
          workoutFids.add(e.workoutFirestoreId!);
        }
      }
    }

    final exerciseNames = <int, String>{};
    if (workoutFids.isNotEmpty) {
      final masters = await workoutLocalDataSource.getByIds(
        workoutFids.toList(),
      );
      for (final m in masters) {
        exerciseNames[m.workoutId] = m.exerciseName;
      }
    }

    final dateFmt = DateFormat('yyyy-MM-dd');
    final timeFmt = DateFormat('HH:mm:ss');
    final buf = StringBuffer();
    buf.writeln(_encodeRow(csvHeader));

    for (final log in sorted) {
      final logFid = log.firestoreId;
      final entries = logFid != null
          ? (logToEntries[logFid] ?? const <WorkoutLogEntryModel>[])
          : const <WorkoutLogEntryModel>[];
      final date = dateFmt.format(log.performedAt);
      final time = timeFmt.format(log.performedAt);
      final sessionName = sessionNames[log.sessionId] ?? '';

      if (entries.isEmpty) {
        // Log row with no entries — still emit so the session is
        // visible in the export.
        buf.writeln(
          _encodeRow([date, time, sessionName, '', '', '', '', '', '']),
        );
        continue;
      }

      for (final e in entries) {
        buf.writeln(
          _encodeRow([
            date,
            time,
            sessionName,
            exerciseNames[e.workoutId] ?? '',
            e.sets?.toString() ?? '',
            e.reps?.toString() ?? '',
            e.weight == null
                ? ''
                : e.weight == e.weight!.roundToDouble()
                ? e.weight!.toInt().toString()
                : e.weight!.toString(),
            e.durationSeconds?.toString() ?? '',
            e.notes,
          ]),
        );
      }
    }
    return buf.toString();
  }

  /// Quotes a single CSV row per RFC 4180.
  String _encodeRow(List<String> cells) {
    return cells.map(_encodeCell).join(',');
  }

  String _encodeCell(String value) {
    final needsQuote =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuote) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}