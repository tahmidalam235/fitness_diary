import 'package:flutter/material.dart';

import 'app_radius.dart';

/// Material 3 light + dark themes for the app.
///
/// Colors come from `ColorScheme.fromSeed`. Component themes use
/// the [AppRadius] token scale for shape consistency and a layered
/// shadow system for a refined "premium" feel.
class AppTheme {
  const AppTheme._();

  /// Seed color used to generate the Material 3 color scheme.
  /// A vivid electric blue that produces a bright, modern palette
  /// with strong contrast and vibrant tonal accents.
  static const Color _seedColor = Color(0xFF2563EB); // Electric blue

  // -- Workout-tuned accent palette ----------------------------------------

  /// Power orange — used for streaks, "fire" stats and high-energy accents.
  static const Color powerOrange = Color(0xFFFF6A1A);

  /// Lime green — used for completion states, PRs, fresh sessions.
  static const Color limeGreen = Color(0xFF84CC16);

  /// Deep violet — used for premium highlights and "all-time" stats.
  static const Color deepViolet = Color(0xFF7C3AED);

  /// Cyan accent — used for water/recovery hints and Today-day labels.
  static const Color accentCyan = Color(0xFF06B6D4);

  /// Frost blue — used for "frozen" days (rest day / streak protection).
  static const Color frostBlue = Color(0xFF60A5FA);

  /// Brand dark surface — used for premium tile backgrounds on auth flows.
  static const Color brandDark = Color(0xFF0B1020);

  /// Hero gradient — bright, multi-stop, used on banner cards, avatars,
  /// and CTA buttons. Reads as premium without being garish.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF22D3EE), // cyan-400
      Color(0xFF3B82F6), // blue-500
      Color(0xFF8B5CF6), // violet-500
    ],
  );

  /// Hero gradient (vertical) — same palette, vertical orientation for
  /// splash / hero headers where a top-to-bottom energy flow reads better.
  static const LinearGradient heroGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF22D3EE),
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
    ],
  );

  /// Power gradient — energetic, used for streak / fire stats and "go"
  /// CTAs. Hotter than the hero gradient, reads as "workout intensity".
  static const LinearGradient powerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFB923C), // orange-400
      Color(0xFFEF4444), // red-500
      Color(0xFFEC4899), // pink-500
    ],
  );

  /// Warm gradient — used for streak / fire stats.
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFB923C), // orange-400
      Color(0xFFEF4444), // red-500
    ],
  );

  /// Fresh gradient — emerald → cyan, used for completion / "active" stats.
  static const LinearGradient freshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF34D399), // emerald-400
      Color(0xFF06B6D4), // cyan-500
    ],
  );

  /// Victory gradient — emerald → lime → cyan, used for PR / "you did it"
  /// moments and personal-record badges.
  static const LinearGradient victoryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF22C55E), // green-500
      Color(0xFF84CC16), // lime-500
      Color(0xFF06B6D4), // cyan-500
    ],
  );

  /// Deep gradient — violet → indigo, used for dark / premium hero panels.
  static const LinearGradient deepGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7C3AED), // violet-600
      Color(0xFF312E81), // indigo-900
    ],
  );

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return _baseTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return _baseTheme(colorScheme);
  }

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkSparkle.splashFactory,
    );

    // Workout-tuned typography: tighter letter-spacing on big headlines,
    // heavier weights, and a clear hierarchy from display → body.
    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        height: 1.0,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.2,
        height: 1.0,
      ),
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.05,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.1,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.2,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.0,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: isDark
          ? colorScheme.surface
          : const Color(0xFFF6F8FB), // subtle warm-bright surface
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor:
            isDark ? colorScheme.surface : const Color(0xFFF6F8FB),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        toolbarHeight: 60,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        shadowColor: colorScheme.shadow.withValues(alpha: 0.06),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w700,
        ),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        extendedTextStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        iconColor: colorScheme.onSurfaceVariant,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 10,
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.55),
        labelStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.0),
          width: 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        color: colorScheme.primary,
      ),
    );
  }
}

/// Layered, soft shadow stack used on premium cards and FABs.
///
/// Single `BoxShadow` looks flat on Material 3 surfaces; a stack of two
/// (a tight dark base + a wider diffuse) creates a refined lift that
/// reads as "high-class" without going skeuomorphic.
List<BoxShadow> layeredShadow({
  required ColorScheme colorScheme,
  double intensity = 1.0,
}) {
  final base = colorScheme.shadow.withValues(alpha: 0.08 * intensity);
  final soft = colorScheme.shadow.withValues(alpha: 0.05 * intensity);
  final glow = colorScheme.primary.withValues(alpha: 0.06 * intensity);
  return [
    BoxShadow(
      color: base,
      blurRadius: 12 * intensity,
      offset: Offset(0, 4 * intensity),
    ),
    BoxShadow(
      color: soft,
      blurRadius: 28 * intensity,
      offset: Offset(0, 14 * intensity),
    ),
    BoxShadow(
      color: glow,
      blurRadius: 40 * intensity,
      offset: Offset(0, 18 * intensity),
    ),
  ];
}

/// Subtle shadow for compact elements (chips, small buttons, inline tags).
List<BoxShadow> subtleShadow({double intensity = 1.0}) {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04 * intensity),
      blurRadius: 6 * intensity,
      offset: Offset(0, 2 * intensity),
    ),
  ];
}
