import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// A premium auth-styled text field: gradient icon tile on the left,
/// label-as-placeholder, optional trailing widget (eye toggle, etc.),
/// and an inline error block. Used by both login and signup flows so
/// they share a single visual identity.
class AppAuthField extends StatelessWidget {
  const AppAuthField({
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.trailing,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasError
              ? theme.colorScheme.error.withValues(alpha: 0.7)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: hasError
            ? null
            : [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x406366F1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onSubmitted: onSubmitted,
                  autofillHints: autofillHints,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    labelText: label,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    hintText: hint,
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: theme.colorScheme.error,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Branded gradient-tile logo mark used above the form on auth pages.
/// Uses the dark brand surface and the same logo asset as the splash.
class AppAuthBrandMark extends StatelessWidget {
  const AppAuthBrandMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.brandDark, Color(0xFF1E1B4B)],
          ),
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: EdgeInsets.all(size * 0.18),
        child: Image.asset(
          'assets/logo/fitness_diary_compact.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Banner error shown above the primary CTA on auth pages.
class AppAuthBannerError extends StatelessWidget {
  const AppAuthBannerError({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Eye-toggle button used as the trailing widget on password fields.
class AppObscureToggle extends StatelessWidget {
  const AppObscureToggle({
    required this.isObscured,
    required this.onTap,
    super.key,
  });

  final bool isObscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: 20,
      ),
      tooltip: isObscured ? 'Show password' : 'Hide password',
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Full-bleed branded background for auth pages — same hero gradient
/// as the splash but with a softer radial fade so the form remains
/// the focal point.
class AppAuthBackground extends StatelessWidget {
  const AppAuthBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: _blur(280, Colors.white.withValues(alpha: 0.20)),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: _blur(360, const Color(0xFFEC4899).withValues(alpha: 0.30)),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _blur(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: size, spreadRadius: size / 6),
          ],
        ),
      ),
    );
  }
}
