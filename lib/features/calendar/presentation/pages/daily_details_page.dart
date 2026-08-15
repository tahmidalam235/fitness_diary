import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../bloc/daily_details_bloc.dart';
import '../bloc/daily_details_event.dart';
import '../bloc/daily_details_state.dart';
import '../widgets/day_log_card.dart';

/// Parses a `yyyy-MM-dd` URL segment into a [DateTime] (midnight, local).
/// Returns `null` for malformed input so the page can fall back to an
/// empty state without crashing.
DateTime? parseDayParam(String raw) {
  final parts = raw.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}

/// Daily Workout Details page. Shows every session performed on [date]
/// along with its per-set entries, or an empty state if no workout was
/// completed that day.
class DailyDetailsPage extends StatelessWidget {
  const DailyDetailsPage({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pretty = DateFormat.yMMMMEEEEd(l10n.localeName).format(date);

    // If the URL had a malformed date, we still render the empty state
    // but skip subscribing to a stream.
    final validDate = DateTime(date.year, date.month, date.day);

    return BlocProvider<DailyDetailsBloc>(
      create: (_) =>
          getIt<DailyDetailsBloc>()..add(DaySelectedEvent(validDate)),
      child: AppScaffold(
        title: l10n.dailyDetailsTitle,
        useNavigationRail: true,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                            Icons.event_note_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.dailyDetailsTitle.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pretty,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.dailyDetailsDateLabel(
                        DateFormat.yMd(l10n.localeName).format(date),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<DailyDetailsBloc, DailyDetailsState>(
                builder: (context, state) {
                  if (state is DailyDetailsInitial ||
                      state is DailyDetailsLoading) {
                    return const AppLoadingIndicator();
                  }
                  if (state is DailyDetailsError) {
                    return AppEmptyState(
                      title: l10n.commonErrorTitle,
                      message: state.failure.message,
                      icon: Icons.error_outline_rounded,
                    );
                  }
                  if (state is DailyDetailsEmpty) {
                    return AppEmptyState(
                      title: l10n.dailyDetailsEmptyTitle,
                      message: l10n.dailyDetailsEmptyMessage,
                      icon: Icons.event_busy_rounded,
                    );
                  }
                  if (state is DailyDetailsLoaded) {
                    if (state.groups.isEmpty) {
                      return AppEmptyState(
                        title: l10n.dailyDetailsEmptyTitle,
                        message: l10n.dailyDetailsEmptyMessage,
                        icon: Icons.event_busy_rounded,
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      itemCount: state.groups.length,
                      itemBuilder: (context, index) {
                        final group = state.groups[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: DayLogCard(
                            group: group,
                            sessionsById: state.sessionsById,
                            workoutsById: state.workoutsById,
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
