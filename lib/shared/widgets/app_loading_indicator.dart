import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// Centered, theme-aware loading indicator.
///
/// Renders a tinted gradient dual-arc loader that feels more "workout
/// app" than the stock CircularProgressIndicator.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SizedBox(
          width: 36,
          height: 36,
          child: ShaderMask(
            shaderCallback: (rect) =>
                AppTheme.heroGradient.createShader(rect),
            blendMode: BlendMode.srcIn,
            child: const CircularProgressIndicator(
              strokeWidth: 3.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
