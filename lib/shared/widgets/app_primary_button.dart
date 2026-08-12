import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';

/// FilledButton wrapper that handles icon + label + loading state.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return FilledButton(
        onPressed: null,
        child: const SizedBox(
          height: AppIconSize.md,
          width: AppIconSize.md,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}
