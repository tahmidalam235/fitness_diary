import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/suggestions_read_service.dart';
import '../../data/suggestions_repository.dart';

/// "Suggestions" page reachable from the top-right 3-dot menu.
///
/// Streams the list of workouts the user has performed during the
/// previous 30 days but NOT during the previous 3 days, sorted by
/// frequency (most-trained first). On first load the page also marks
/// the suggestions as viewed so the menu's red dot clears.
class SuggestionsPage extends StatefulWidget {
  const SuggestionsPage({super.key});

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  late final SuggestionsRepository _repository;
  late final SuggestionsReadService _readService;
  bool _markedViewed = false;

  @override
  void initState() {
    super.initState();
    _repository = SuggestionsRepository();
    _readService = getIt<SuggestionsReadService>();
  }

  void _onSuggestionsLoaded(List<SuggestedWorkout> list) {
    if (_markedViewed) return;
    _markedViewed = true;
    // Fire-and-forget: clearing the red dot is independent of render.
    unawaited(_readService.markViewed());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Suggestions',
      showBackButton: true,
      useNavigationRail: true,
      body: Column(
        children: [
          const _HeroHeader(),
          Expanded(
            child: StreamBuilder<List<SuggestedWorkout>>(
              stream: _repository.watchSuggestions(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: AppLoadingIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return const _EmptyState();
                }
                _onSuggestionsLoaded(list);
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                  itemBuilder: (context, i) =>
                      _SuggestionCard(suggestion: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppTheme.deepGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepCrimson.withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 12),
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
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TRAINING SUGGESTIONS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Time to revisit',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Workouts from your last 30 days you haven't trained in 3+ days",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});

  final SuggestedWorkout suggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('MMM d').format(suggestion.lastPerformedAt);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  suggestion.bodyPart?.icon ?? Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      suggestion.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (suggestion.bodyPart != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          suggestion.bodyPart!.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _FrequencyBadge(count: suggestion.timesPerformedLast30Days),
            ],
          ),
          const Gap(AppSpacing.sm),
          Container(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          const Gap(AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const Gap(AppSpacing.xs),
              Expanded(
                child: Text(
                  'Last performed: $dateLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FrequencyBadge extends StatelessWidget {
  const _FrequencyBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count == 1 ? '1× in 30d' : '$count× in 30d';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.freshGradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.freshGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.limeGreen.withValues(alpha: 0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
            ),
            const Gap(AppSpacing.md),
            Text(
              'No new workout suggestions right now.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              "You're up to date on every workout from your last 30 days.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// `unawaited` lives in `dart:async` (imported above).
