import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../dashboard/presentation/widgets/drawer_progress_section.dart';

/// Full-screen progress overview. Reuses [DrawerProgressSection] so the
/// monthly + yearly breakdowns stay consistent with the drawer view.
/// The section is rendered without its outer container here so it
/// expands to fill the screen width.
class HistoryOverviewPage extends StatelessWidget {
  const HistoryOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Progress',
      showBackButton: true,
      useNavigationRail: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          // Hero header.
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your progress',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Monthly and yearly workout history at a glance.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Progress details. Force-expanded on first build so the user
          // sees the full breakdown immediately.
          const DrawerProgressSection(initiallyExpanded: true),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.historyPeriodEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps [DrawerProgressSection] and forces it open on first build so
/// the overview page shows the full breakdown by default.
class _ForceExpandedProgress extends StatefulWidget {
  const _ForceExpandedProgress();

  @override
  State<_ForceExpandedProgress> createState() => _ForceExpandedProgressState();
}

class _ForceExpandedProgressState extends State<_ForceExpandedProgress> {
  @override
  Widget build(BuildContext context) {
    // Render the DrawerProgressSection with initiallyExpanded=true so
    // the user lands on the full breakdown instead of having to tap.
    return const DrawerProgressSection(initiallyExpanded: true);
  }
}
