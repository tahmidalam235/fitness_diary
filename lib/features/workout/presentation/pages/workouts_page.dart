import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_scaffold.dart';

/// Global Workout Library Placeholder.
///
/// Reverted to "Coming Soon" state as per user request to restore "perfect" UI.
class WorkoutsPage extends StatelessWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.workoutsTitle,
      useNavigationRail: true,
      body: Center(
        child: AppEmptyState(
          title: l10n.workoutsComingSoon,
          message:
              'A global exercise catalog is coming soon to help you track your progress across all sessions.',
          icon: Icons.construction_rounded,
        ),
      ),
    );
  }
}
