import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// Workout-styled section header used to anchor major page sections.
///
/// Renders a 4×18 colored vertical bar followed by an uppercase title
/// with letter-spacing — reads as "professional, fitness-magazine".
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    this.trailing,
    this.icon,
    this.accent,
    super.key,
  });

  final String title;
  final Widget? trailing;
  final IconData? icon;

  /// Optional accent override; defaults to the theme primary color.
  final Color? accent;

  /// Workout-styled title text style for inline use (e.g. inside a card
  /// header next to an icon). Matches the look of [AppSectionHeader]
  /// without the bar + icon row.
  static TextStyle? titleStyle(ThemeData theme) {
    return theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 1.4,
      color: theme.colorScheme.onSurface,
      fontSize: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: theme.colorScheme.onSurface,
                fontSize: 12,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Gradient-filled circular avatar / icon tile with a soft colored glow.
///
/// Sizes: 32 (compact), 40 (default), 48 (medium), 56 (large).
class AppGradientIconTile extends StatelessWidget {
  const AppGradientIconTile({
    required this.icon,
    this.size = 40,
    this.gradient = AppTheme.heroGradient,
    this.iconSize,
    this.borderColor,
    this.glow,
    super.key,
  });

  final IconData icon;
  final double size;
  final Gradient gradient;
  final double? iconSize;
  final Color? borderColor;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final s = iconSize ?? (size * 0.5);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
        boxShadow: [
          if (glow != null)
            BoxShadow(
              color: glow!,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: s),
    );
  }
}

/// Soft, semi-transparent tile used as a prefix / accent on stat cards and
/// list items. Uses a tinted background instead of a heavy gradient.
class AppTintedIconTile extends StatelessWidget {
  const AppTintedIconTile({
    super.key,
    required this.icon,
    this.size = 36,
    this.color = const Color(0xFFEF4444),
    this.backgroundOpacity = 0.14,
    this.borderOpacity = 0.3,
    this.iconSize,
  }) : tint = null,
       outlineColor = null;

  const AppTintedIconTile.fromTint({
    super.key,
    required this.icon,
    required this.tint,
    this.size = 36,
    this.iconSize,
  }) : color = const Color(0xFFEF4444),
       backgroundOpacity = 0,
       borderOpacity = 0,
       outlineColor = null;

  /// Outline variant — used as a soft, neutral icon box.
  const AppTintedIconTile.outline({
    super.key,
    required this.icon,
    this.size = 36,
    this.iconSize,
    required this.outlineColor,
  }) : color = const Color(0xFFEF4444),
       backgroundOpacity = 0,
       borderOpacity = 0,
       tint = null;

  final IconData icon;
  final double size;
  final double? iconSize;
  final Color color;
  final double backgroundOpacity;
  final double borderOpacity;
  final Color? tint;
  final Color? outlineColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    Color border;
    if (tint != null) {
      bg = tint!;
      border = Colors.transparent;
    } else if (outlineColor != null) {
      bg = theme.colorScheme.surfaceContainerHighest;
      border = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    } else {
      bg = color.withValues(alpha: backgroundOpacity);
      border = color.withValues(alpha: borderOpacity);
    }
    final s = iconSize ?? (size * 0.5);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: border, width: 1),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: s,
        color: outlineColor != null
            ? theme.colorScheme.onSurfaceVariant
            : color,
      ),
    );
  }
}

/// Workout-styled "chip" used in card meta rows.
///
/// Renders a 14-px leading icon + label inside a tinted pill. Body parts,
/// sets/reps, durations etc. all use this shape for a consistent visual
/// rhythm across cards.
class AppStatChip extends StatelessWidget {
  const AppStatChip({
    required this.label,
    required this.value,
    this.icon,
    this.color,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: tint.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tint),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            '$label ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}