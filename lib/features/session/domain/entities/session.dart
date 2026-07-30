import 'package:equatable/equatable.dart';

/// Domain entity representing a workout-session template (e.g. Push, Pull).
///
/// Immutable. Use [copyWith] to derive a new instance when a single
/// field changes (e.g. updating the name).
class Session extends Equatable {
  const Session({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.workoutCount = 0,
  });

  /// Database primary key. `null` for not-yet-persisted sessions.
  final int? id;

  /// Display name, validated to be 2–60 characters.
  final String name;

  /// Optional user-provided notes.
  final String description;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// Number of exercises attached to this session. Computed in the
  /// data layer; defaults to `0` for new sessions.
  final int workoutCount;

  Session copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? workoutCount,
  }) {
    return Session(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workoutCount: workoutCount ?? this.workoutCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        createdAt,
        updatedAt,
        workoutCount,
      ];
}