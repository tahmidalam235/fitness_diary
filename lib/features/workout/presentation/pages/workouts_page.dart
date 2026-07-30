import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_scaffold.dart';

/// Placeholder for the Workout Library. Wired to the router so the
/// drawer can route here; real implementation arrives in a future
/// milestone.
class WorkoutsPage extends StatelessWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.workoutsTitle,
      useNavigationRail: true,
      body: AppEmptyState(
        icon: Icons.fitness_center_rounded,
        title: l10n.workoutsComingSoon,
      ),
    );
  }
}