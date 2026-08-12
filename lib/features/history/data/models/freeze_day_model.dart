import '../../domain/entities/freeze_day.dart';

/// JSON adapter for [FreezeDay]. Mirrors the model classes used by
/// the other features so the sync layer can speak one shape for every
/// entity.
class FreezeDayModel {
  const FreezeDayModel({
    required this.firestoreId,
    required this.day,
    this.note = '',
    this.updatedAt,
  });

  factory FreezeDayModel.fromJson(Map<String, dynamic> json) {
    return FreezeDayModel(
      firestoreId: json['firestoreId'] as String,
      day: DateTime.fromMillisecondsSinceEpoch(json['day'] as int),
      note: (json['note'] as String?) ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
    );
  }

  /// May be empty for legacy rows whose `firestoreId` column hasn't been
  /// backfilled yet (shouldn't happen post-v10, but defensive).
  final String firestoreId;
  final DateTime day;
  final String note;
  final DateTime? updatedAt;

  FreezeDay toEntity() => FreezeDay(day: day, note: note);

  Map<String, dynamic> toJson() => {
    'firestoreId': firestoreId,
    'day': day.millisecondsSinceEpoch,
    'note': note,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
  };
}
