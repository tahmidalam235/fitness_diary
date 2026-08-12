import 'package:flutter/material.dart';

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
