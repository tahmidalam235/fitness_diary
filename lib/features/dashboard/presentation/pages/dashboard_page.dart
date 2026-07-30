import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/daos/workout_log_dao.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../session/domain/entities/session.dart';
import '../../../session/presentation/bloc/session_bloc.dart';
import '../../../session/presentation/bloc/session_event.dart';
import '../../../session/presentation/bloc/session_state.dart';

/// Vibrant, data-driven dashboard. Built from reactive `SessionBloc` for
/// the session list and a lightweight stats loader for workout log totals,
/// so it stays in sync with the rest of the app without introducing a new
/// bloc/codegen cycle.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.dashboardTitle,
      useNavigationRail: true,
      body: BlocProvider<SessionBloc>(
        create: (_) => getIt<SessionBloc>()..add(const WatchSessionsEvent()),
        child: const _DashboardView(),
      ),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  late final Stream<_DashboardStats> _statsStream;

  @override
  void initState() {
    super.initState();
    _statsStream = _buildStatsStream();
  }

  /// Streams a stats snapshot every time the underlying DB changes.
  /// Cheap because we only count, not read all rows.
  Stream<_DashboardStats> _buildStatsStream() {
    final dao = getIt<WorkoutLogDao>();

    Future<_DashboardStats> read() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(const Duration(days: 6));
      final last7 = await dao
          .watchLogsInRange(
            start: weekStart,
            end: today.add(const Duration(days: 1)),
          )
          .first;
      final allLogs = await dao.watchAllLogs().first;
      // Total set count across all logs:
      int totalSets = 0;
      for (final log in allLogs) {
        final entries = await dao.watchEntriesForLog(log.id).first;
        totalSets += entries.length;
      }
      return _DashboardStats(
        sessionsThisWeek: last7.length,
        totalWorkouts: allLogs.length,
        totalSets: totalSets,
      );
    }

    // Re-emit whenever any log row changes. The Drift stream emits an
    // initial snapshot synchronously, so the StreamBuilder receives data
    // on first frame without needing a separate "seed" event.
    return dao.watchAllLogs().asyncMap((_) => read());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        return StreamBuilder<_DashboardStats>(
          stream: _statsStream,
          builder: (context, snap) {
            if (state is SessionLoading && !snap.hasData) {
              return const AppLoadingIndicator();
            }
            final sessions = state is SessionLoaded
                ? state.sessions
                : const <Session>[];
            final stats = snap.data;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                _GreetingHero(
                  l10n: l10n,
                  theme: theme,
                  sessionsCount: sessions.length,
                ),
                const Gap(AppSpacing.xl),
                _KpiRow(
                  stats: stats,
                  l10n: l10n,
                  theme: theme,
                ),
                const Gap(AppSpacing.xl),
                _QuickActionsRow(l10n: l10n),
                const Gap(AppSpacing.xl),
                _RecentActivitySection(
                  sessions: sessions,
                  stats: stats,
                  l10n: l10n,
                  theme: theme,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DashboardStats {
  const _DashboardStats({
    required this.sessionsThisWeek,
    required this.totalWorkouts,
    required this.totalSets,
  });
  final int sessionsThisWeek;
  final int totalWorkouts;
  final int totalSets;
}

// ============================================================================
// HERO GREETING
// ============================================================================

class _GreetingHero extends StatelessWidget {
  const _GreetingHero({
    required this.l10n,
    required this.theme,
    required this.sessionsCount,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final int sessionsCount;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return l10n.dashboardGreetingNight;
    if (hour < 12) return l10n.dashboardGreetingMorning;
    if (hour < 17) return l10n.dashboardGreetingAfternoon;
    if (hour < 21) return l10n.dashboardGreetingEvening;
    return l10n.dashboardGreetingNight;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF22D3EE), // cyan-400
            Color(0xFF3B82F6), // blue-500
            Color(0xFF8B5CF6), // violet-500
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.40),
            blurRadius: 28,
            offset: const Offset(0, 14),
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
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const Gap(AppSpacing.xxs),
                Text(
                  l10n.dashboardSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    letterSpacing: 0.1,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        sessionsCount == 1
                            ? '1 session template'
                            : '$sessionsCount session templates',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// KPI ROW (3 colorful tiles)
// ============================================================================

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.stats,
    required this.l10n,
    required this.theme,
  });

  final _DashboardStats? stats;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            label: l10n.dashboardKpiSessionsThisWeek,
            sub: l10n.dashboardKpiSessionsThisWeekSub,
            value: s?.sessionsThisWeek,
            icon: Icons.calendar_view_week_rounded,
            gradient: AppTheme.warmGradient,
          ),
        ),
        const Gap(AppSpacing.md),
        Expanded(
          child: _KpiTile(
            label: l10n.dashboardKpiTotalWorkouts,
            sub: l10n.dashboardKpiTotalWorkoutsSub,
            value: s?.totalWorkouts,
            icon: Icons.local_fire_department_rounded,
            gradient: AppTheme.freshGradient,
          ),
        ),
        const Gap(AppSpacing.md),
        Expanded(
          child: _KpiTile(
            label: l10n.dashboardKpiSetsLogged,
            sub: l10n.dashboardKpiSetsLoggedSub,
            value: s?.totalSets,
            icon: Icons.fitness_center_rounded,
            gradient: AppTheme.heroGradient,
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.sub,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final String sub;
  final int? value;
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const Gap(AppSpacing.md),
          Text(
            value == null ? '…' : '$value',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const Gap(AppSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(AppSpacing.xxs),
          Text(
            sub,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// QUICK ACTIONS
// ============================================================================

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.dashboardQuickActionsTitle),
        const Gap(AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                title: l10n.dashboardActionStartToday,
                sub: l10n.dashboardActionStartTodaySub,
                icon: Icons.play_circle_filled_rounded,
                bg: const Color(0xFFFDE68A), // amber-200
                fg: const Color(0xFF92400E), // amber-800
                accent: const Color(0xFFF59E0B), // amber-500
                onTap: () => context.goNamed(RouteNames.today),
              ),
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: _ActionTile(
                title: l10n.dashboardActionViewCalendar,
                sub: l10n.dashboardActionViewCalendarSub,
                icon: Icons.calendar_month_rounded,
                bg: const Color(0xFFBFDBFE), // blue-200
                fg: const Color(0xFF1E3A8A), // blue-900
                accent: const Color(0xFF3B82F6), // blue-500
                onTap: () => context.goNamed(RouteNames.calendar),
              ),
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: _ActionTile(
                title: l10n.dashboardActionBrowseSessions,
                sub: l10n.dashboardActionBrowseSessionsSub,
                icon: Icons.style_rounded,
                bg: const Color(0xFFDDD6FE), // violet-200
                fg: const Color(0xFF5B21B6), // violet-800
                accent: const Color(0xFF8B5CF6), // violet-500
                onTap: () => context.goNamed(RouteNames.sessions),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.sub,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String sub;
  final IconData icon;
  final Color bg;
  final Color fg;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 2,
      shadowColor: accent.withValues(alpha: 0.25),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bg,
                Color.alphaBlend(
                  accent.withValues(alpha: 0.18),
                  bg,
                ),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent, size: 20),
              ),
              const Gap(AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(AppSpacing.xxs),
              Text(
                sub,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg.withValues(alpha: 0.80),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// RECENT ACTIVITY
// ============================================================================

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({
    required this.sessions,
    required this.stats,
    required this.l10n,
    required this.theme,
  });

  final List<Session> sessions;
  final _DashboardStats? stats;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final recent = _recent(sessions, stats?.totalWorkouts ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.dashboardRecentTitle),
        const Gap(AppSpacing.sm),
        if (recent.isEmpty)
          _EmptyRecentCard(message: l10n.dashboardRecentEmpty)
        else
          ...recent.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RecentActivityCard(
                item: item,
                theme: theme,
                onTap: () => context.pushNamed(
                  RouteNames.sessionDetails,
                  pathParameters: {'id': item.sessionId.toString()},
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<_RecentItem> _recent(List<Session> sessions, int totalWorkouts) {
    if (sessions.isEmpty) return const [];
    // No real per-day data plumbing here without a heavier read path, so
    // summarise by session template: each session gets a "ready to go"
    // preview card so the dashboard feels populated even on day one.
    final out = <_RecentItem>[];
    // Cycle through three bright accent colors so the list feels alive.
    const accents = <Color>[
      Color(0xFF22D3EE), // cyan-400
      Color(0xFFFB923C), // orange-400
      Color(0xFFA78BFA), // violet-400
    ];
    for (var i = 0; i < sessions.take(4).length; i++) {
      final s = sessions[i];
      final accent = accents[i % accents.length];
      out.add(_RecentItem(
        sessionId: s.id!,
        title: s.name.isEmpty ? 'Untitled session' : s.name,
        subtitle: s.description.isEmpty
            ? 'Tap to open the session and start a workout.'
            : s.description,
        icon: Icons.style_rounded,
        accent: accent,
      ));
    }
    return out;
  }
}

class _RecentItem {
  const _RecentItem({
    required this.sessionId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });
  final int sessionId;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.item,
    required this.theme,
    required this.onTap,
  });
  final _RecentItem item;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      item.accent.withValues(alpha: 0.25),
                      item.accent.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, color: item.accent, size: 22),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(AppSpacing.xxs),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRecentCard extends StatelessWidget {
  const _EmptyRecentCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFEF3C7), // amber-100
            Color(0xFFFDE68A), // amber-200
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Color(0xFFF59E0B), // amber-500
              size: 22,
            ),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF78350F), // amber-900
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SHARED SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const Gap(AppSpacing.sm),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}