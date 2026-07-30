import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/session.dart';

/// Maps between Drift [db.Session] rows (the generated data class) and
/// the domain [Session] entity.
///
/// Kept as a thin wrapper rather than extending the generated class so
/// the domain layer never depends on the database schema directly.
class SessionModel {
  const SessionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.workoutCount,
  });

  factory SessionModel.fromDrift(
    db.Session row, {
    int workoutCount = 0,
  }) {
    return SessionModel(
      id: row.id,
      name: row.name,
      description: row.description,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      workoutCount: workoutCount,
    );
  }

  final int? id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int workoutCount;

  Session toEntity() {
    return Session(
      id: id,
      name: name,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
      workoutCount: workoutCount,
    );
  }

  /// Companion used when inserting a new row.
  db.SessionsCompanion toInsertCompanion() {
    return db.SessionsCompanion.insert(
      name: name,
      description: Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  /// Companion used when updating an existing row.
  db.SessionsCompanion toUpdateCompanion() {
    return db.SessionsCompanion(
      id: Value(id!),
      name: Value(name),
      description: Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}