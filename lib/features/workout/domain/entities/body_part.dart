import 'package:flutter/material.dart';

/// The six major muscle-group buckets used by the muscle-wise filter
/// UI on the session details / Add Workout flow. Derived from the
/// comments in [BodyPart] and kept in this separate enum so the
/// filter sheet can iterate a stable ordered list without inventing
/// the order inline. Persisted nowhere — purely a presentation
/// concern, so this enum is safe to add at any time.
enum MajorMuscleGroup {
  chest,
  back,
  shoulders,
  arms,
  legs,
  core,
  other;

  /// Human-readable label for the major muscle group. English-only,
  /// matching the rest of the app's l10n.
  String get label {
    switch (this) {
      case MajorMuscleGroup.chest:
        return 'Chest';
      case MajorMuscleGroup.back:
        return 'Back';
      case MajorMuscleGroup.shoulders:
        return 'Shoulders';
      case MajorMuscleGroup.arms:
        return 'Arms';
      case MajorMuscleGroup.legs:
        return 'Legs';
      case MajorMuscleGroup.core:
        return 'Core';
      case MajorMuscleGroup.other:
        return 'Other';
    }
  }

  /// Material icon for the major muscle group. Several groups share
  /// an icon for visual rhythm; the label disambiguates.
  IconData get icon {
    switch (this) {
      case MajorMuscleGroup.chest:
        return Icons.favorite_rounded;
      case MajorMuscleGroup.back:
        return Icons.accessibility_rounded;
      case MajorMuscleGroup.shoulders:
        return Icons.accessibility_new_rounded;
      case MajorMuscleGroup.arms:
        return Icons.fitness_center_rounded;
      case MajorMuscleGroup.legs:
        return Icons.directions_run_rounded;
      case MajorMuscleGroup.core:
        return Icons.donut_small_rounded;
      case MajorMuscleGroup.other:
        return Icons.more_horiz_rounded;
    }
  }
}

/// Mapping from every [BodyPart] enum value to its parent
/// [MajorMuscleGroup] bucket. The mapping mirrors the section
/// comments already present on [BodyPart] so we never end up with
/// two competing "which bucket does X belong in" definitions.
///
/// Lives as a top-level extension so callers can write
/// `bodyPart.majorGroup` next to the existing `bodyPart.label` /
/// `bodyPart.icon` accessors and stay readable.
extension BodyPartGrouping on BodyPart {
  /// The major muscle group this body part belongs to.
  MajorMuscleGroup get majorGroup {
    switch (this) {
      // Chest
      case BodyPart.upperChest:
      case BodyPart.lowerChest:
      case BodyPart.fullChest:
        return MajorMuscleGroup.chest;
      // Back
      case BodyPart.back:
      case BodyPart.lats:
        return MajorMuscleGroup.back;
      // Shoulders
      case BodyPart.shoulders:
      case BodyPart.frontDelts:
      case BodyPart.rearDelts:
      case BodyPart.traps:
        return MajorMuscleGroup.shoulders;
      // Arms
      case BodyPart.biceps:
      case BodyPart.triceps:
      case BodyPart.forearms:
      case BodyPart.wrists:
        return MajorMuscleGroup.arms;
      // Legs
      case BodyPart.quads:
      case BodyPart.hamstrings:
      case BodyPart.glutes:
      case BodyPart.calves:
      case BodyPart.fullLegs:
        return MajorMuscleGroup.legs;
      // Core
      case BodyPart.upperAbs:
      case BodyPart.lowerAbs:
      case BodyPart.obliques:
      case BodyPart.core:
        return MajorMuscleGroup.core;
      // Misc
      case BodyPart.cardio:
      case BodyPart.fullBody:
      case BodyPart.other:
        return MajorMuscleGroup.other;
    }
  }
}

/// Pre-computed bucketing of every [BodyPart] into its parent
/// [MajorMuscleGroup]. Computed once at constant-evaluation time so
/// callers can do `kBodyPartsByGroup[MajorMuscleGroup.chest]` instead
/// of re-scanning `BodyPart.values` on every widget rebuild.
final Map<MajorMuscleGroup, List<BodyPart>> kBodyPartsByGroup = {
  for (final group in kOrderedMajorMuscleGroups)
    group: [
      for (final p in BodyPart.values)
        if (p.majorGroup == group) p,
    ],
};

/// Ordered list of major muscle groups shown in the muscle-wise
/// filter UI. The order is the canonical anatomical flow used by the
/// picker: Chest → Back → Shoulders → Arms → Legs → Core → Other.
const List<MajorMuscleGroup> kOrderedMajorMuscleGroups = [
  MajorMuscleGroup.chest,
  MajorMuscleGroup.back,
  MajorMuscleGroup.shoulders,
  MajorMuscleGroup.arms,
  MajorMuscleGroup.legs,
  MajorMuscleGroup.core,
  MajorMuscleGroup.other,
];

/// The muscle group a workout targets. Persisted by its [name] (stable
/// Dart enum identifier, e.g. `biceps`, `upperChest`) so that renaming
/// a value here is a breaking schema change.
///
/// The label/icon are presentation-only — they live as a static map so
/// the picker and the workout card can render the same source of truth
/// without a separate translation layer.
enum BodyPart {
  // Arms
  biceps,
  triceps,
  forearms,
  wrists,

  // Shoulders
  shoulders,
  frontDelts,
  rearDelts,
  traps,

  // Chest
  upperChest,
  lowerChest,
  fullChest,

  // Back
  back,
  lats,

  // Core
  upperAbs,
  lowerAbs,
  obliques,
  core,

  // Legs
  quads,
  hamstrings,
  glutes,
  calves,
  fullLegs,

  // Misc
  cardio,
  fullBody,
  other;

  /// Human-readable label shown in the picker and on the workout card.
  /// English-only for now (matches the rest of the app's l10n).
  String get label {
    switch (this) {
      case BodyPart.biceps:
        return 'Biceps';
      case BodyPart.triceps:
        return 'Triceps';
      case BodyPart.forearms:
        return 'Forearms';
      case BodyPart.wrists:
        return 'Wrists';
      case BodyPart.shoulders:
        return 'Shoulders';
      case BodyPart.frontDelts:
        return 'Front Delts';
      case BodyPart.rearDelts:
        return 'Rear Delts';
      case BodyPart.traps:
        return 'Traps';
      case BodyPart.upperChest:
        return 'Upper Chest';
      case BodyPart.lowerChest:
        return 'Lower Chest';
      case BodyPart.fullChest:
        return 'Full Chest';
      case BodyPart.back:
        return 'Back';
      case BodyPart.lats:
        return 'Lats';
      case BodyPart.upperAbs:
        return 'Upper Abs';
      case BodyPart.lowerAbs:
        return 'Lower Abs';
      case BodyPart.obliques:
        return 'Obliques';
      case BodyPart.core:
        return 'Core';
      case BodyPart.quads:
        return 'Quads';
      case BodyPart.hamstrings:
        return 'Hamstrings';
      case BodyPart.glutes:
        return 'Glutes';
      case BodyPart.calves:
        return 'Calves';
      case BodyPart.fullLegs:
        return 'Full Legs';
      case BodyPart.cardio:
        return 'Cardio';
      case BodyPart.fullBody:
        return 'Full Body';
      case BodyPart.other:
        return 'Other';
    }
  }

  /// Material icon used in the picker and on the workout card. Material
  /// has no per-muscle icon, so several values share an icon — the label
  /// disambiguates.
  IconData get icon {
    switch (this) {
      case BodyPart.biceps:
      case BodyPart.triceps:
        return Icons.fitness_center_rounded;
      case BodyPart.forearms:
        return Icons.linear_scale_rounded;
      case BodyPart.wrists:
        return Icons.watch_rounded;
      case BodyPart.shoulders:
        return Icons.accessibility_new_rounded;
      case BodyPart.frontDelts:
      case BodyPart.rearDelts:
        return Icons.directions_walk_rounded;
      case BodyPart.traps:
        return Icons.expand_less_rounded;
      case BodyPart.upperChest:
        return Icons.favorite_border_rounded;
      case BodyPart.lowerChest:
      case BodyPart.fullChest:
        return Icons.favorite_rounded;
      case BodyPart.back:
      case BodyPart.fullBody:
        return Icons.accessibility_rounded;
      case BodyPart.lats:
        return Icons.swap_horiz_rounded;
      case BodyPart.upperAbs:
      case BodyPart.lowerAbs:
        return Icons.horizontal_rule_rounded;
      case BodyPart.obliques:
        return Icons.rotate_right_rounded;
      case BodyPart.core:
        return Icons.donut_small_rounded;
      case BodyPart.quads:
      case BodyPart.hamstrings:
      case BodyPart.fullLegs:
        return Icons.directions_run_rounded;
      case BodyPart.glutes:
        return Icons.event_seat_rounded;
      case BodyPart.calves:
        return Icons.straighten_rounded;
      case BodyPart.cardio:
        return Icons.directions_bike_rounded;
      case BodyPart.other:
        return Icons.more_horiz_rounded;
    }
  }

  /// Stable serialisation identifier. Defaults to the enum [name].
  String get id => name;

  /// Resolve a serialised id back to its enum value. Returns `null` for
  /// unknown / missing values so callers can fall back gracefully when
  /// reading older data.
  static BodyPart? fromId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final part in BodyPart.values) {
      if (part.id == id) return part;
    }
    return null;
  }
}
