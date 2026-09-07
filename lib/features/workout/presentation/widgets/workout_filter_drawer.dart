import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/usecase/no_params.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_workout_card.dart';
import '../../domain/entities/body_part.dart';
import '../../domain/entities/workout.dart';
import '../../domain/usecases/watch_workouts.dart';

/// Hierarchical workout filter for the Add Session page.
///
/// Step 3 spans *every* workout across every existing session whose
/// `targetedBodyPart` matches the chosen [BodyPart], so the same
/// workout may surface multiple times under different parent
/// sessions. Selecting a workout adds it to today without navigating
/// into its original session.
class WorkoutFilterDrawer extends StatefulWidget {
  const WorkoutFilterDrawer({
    required this.allWorkouts,
    required this.sessionNameById,
    super.key,
  });

  /// Every workout across every existing session. The drawer groups
  /// and filters this list in-memory — the filter is a pure browsing
  /// preference, not a persisted query.
  final List<Workout> allWorkouts;

  /// Lookup from workout.sessionId to the human-readable session name
  /// so the drawer can show "Push · Bench Press" instead of just
  /// "Bench Press" when the same workout name appears in multiple
  /// sessions.
  final Map<int, String> sessionNameById;

  /// Pushes the drawer as a right-edge slide-in modal route. Returns
  /// the confirmed selection, or `null` if the drawer is dismissed
  /// without picking.
  static Future<List<Workout>?> show(
    BuildContext context, {
    required List<Workout> allWorkouts,
    required Map<int, String> sessionNameById,
  }) {
    return Navigator.of(context).push<List<Workout>>(
      PageRouteBuilder<List<Workout>>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.32),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return WorkoutFilterDrawer(
            allWorkouts: allWorkouts,
            sessionNameById: sessionNameById,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offset = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
          return SlideTransition(position: offset, child: child);
        },
      ),
    );
  }

  @override
  State<WorkoutFilterDrawer> createState() => _WorkoutFilterDrawerState();
}

class _WorkoutFilterDrawerState extends State<WorkoutFilterDrawer> {
  MajorMuscleGroup? _selectedGroup;
  BodyPart? _selectedPart;

  // The drawer is a modal route, so its `widget.allWorkouts` is
  // snapshotted at push-time and does not update when the parent's
  // stream re-emits after an edit. Hold a local copy and refresh it
  // in-place after the edit page pops so the cards reflect the new
  // values immediately.
  late List<Workout> _allWorkouts;

  // Keyed by `Workout.workoutId` — mirrors `_selected` in
  // `_SessionDetailsViewState`.
  final Set<int> _selectedWorkoutIds = <int>{};

  @override
  void initState() {
    super.initState();
    _allWorkouts = widget.allWorkouts;
  }

  void _selectGroup(MajorMuscleGroup group) {
    setState(() {
      _selectedGroup = group;
      _selectedPart = null;
      // Selection doesn't persist across body part boundaries.
      _selectedWorkoutIds.clear();
    });
  }

  void _selectPart(BodyPart part) {
    setState(() {
      _selectedPart = part;
      _selectedWorkoutIds.clear();
    });
  }

  void _backToGroups() {
    setState(() {
      _selectedGroup = null;
      _selectedPart = null;
      _selectedWorkoutIds.clear();
    });
  }

  void _backToParts() {
    setState(() {
      _selectedPart = null;
      _selectedWorkoutIds.clear();
    });
  }

  void _toggleWorkoutSelection(int masterWorkoutId) {
    setState(() {
      if (_selectedWorkoutIds.contains(masterWorkoutId)) {
        _selectedWorkoutIds.remove(masterWorkoutId);
      } else {
        _selectedWorkoutIds.add(masterWorkoutId);
      }
    });
  }

  void _confirmAddSelected() {
    if (_selectedWorkoutIds.isEmpty) return;
    final selected = <Workout>[
      for (final w in _matchingWorkouts)
        if (_selectedWorkoutIds.contains(w.workoutId)) w,
    ];
    if (selected.isEmpty) return;
    Navigator.of(context).pop<List<Workout>>(selected);
  }

  /// Opens the existing Edit Workout page. The form emits its own
  /// "Workout updated" snackbar before popping; on return we refresh
  /// `_allWorkouts` from the same `WatchAllWorkouts` stream the
  /// parent uses, so the drawer's cards reflect the new values
  /// immediately instead of waiting for the user to close and reopen
  /// the drawer.
  Future<void> _openEditWorkout(Workout w) async {
    await context.pushNamed(
      RouteNames.workoutEdit,
      pathParameters: {
        'id': w.sessionId.toString(),
        'workoutId': w.id.toString(),
      },
    );
    if (!mounted) return;
    final result = await getIt<WatchAllWorkouts>()(const NoParams()).first;
    if (!mounted) return;
    result.fold(
      (_) {},
      (workouts) {
        setState(() {
          _allWorkouts = workouts;
          // The edited workout may have moved to a different body
          // part — drop any stale selection that's no longer in
          // the visible list so the bottom action bar stays
          // consistent.
          final liveIds = <int>{for (final x in workouts) x.workoutId};
          _selectedWorkoutIds.retainAll(liveIds);
        });
      },
    );
  }

  /// Workouts matching the currently-selected specific body part. The
  /// drawer shows this list on the third step. Stable-sorted by name
  /// so the user can scan it predictably regardless of insertion
  /// order in the source list.
  List<Workout> get _matchingWorkouts {
    final part = _selectedPart;
    if (part == null) return const <Workout>[];
    final matches = <Workout>[
      for (final w in _allWorkouts)
        if (w.targetedBodyPart == part) w,
    ]..sort(
        (a, b) => a.exerciseName.toLowerCase().compareTo(
          b.exerciseName.toLowerCase(),
        ),
      );
    return matches;
  }

  /// Only show major groups that actually have at least one workout
  /// in the dataset, so the user doesn't have to drill into empty
  /// groups.
  List<MajorMuscleGroup> get _availableGroups {
    final available = <MajorMuscleGroup>{};
    for (final w in _allWorkouts) {
      final part = w.targetedBodyPart;
      if (part == null) continue;
      available.add(part.majorGroup);
    }
    return [
      for (final g in kOrderedMajorMuscleGroups)
        if (available.contains(g)) g,
    ];
  }

  /// Specific body parts inside the chosen group that actually have
  /// at least one workout assigned to them.
  List<BodyPart> get _availableParts {
    final group = _selectedGroup;
    if (group == null) return const <BodyPart>[];
    final available = <BodyPart>{};
    for (final w in _allWorkouts) {
      final part = w.targetedBodyPart;
      if (part == null) continue;
      if (part.majorGroup == group) available.add(part);
    }
    return [
      for (final p in kBodyPartsByGroup[group]!)
        if (available.contains(p)) p,
    ];
  }

  /// Title shown in the drawer header — changes as the user drills
  /// down so they always know which level they're on.
  String _stepTitle(AppLocalizations l10n) {
    if (_selectedPart != null) return _selectedPart!.label;
    if (_selectedGroup != null) return _selectedGroup!.label;
    return l10n.workoutFilterByMuscle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Pin the drawer to 92% of the screen width on phones and a
    // comfortable max on tablets so it always feels anchored to the
    // right edge instead of stretching fullscreen.
    final media = MediaQuery.of(context);
    final width = (media.size.width * 0.92).clamp(280.0, 460.0);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Container(
            width: width,
            height: media.size.height,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(AppRadius.lg),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(-6, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DrawerHeader(
                  title: _stepTitle(l10n),
                  // Show a back button on every step except the first
                  // so the user can step up one level.
                  canGoBack: _selectedGroup != null,
                  onBack: () {
                    if (_selectedPart != null) {
                      _backToParts();
                    } else {
                      _backToGroups();
                    }
                  },
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(child: _buildStep(theme)),
                _BottomActionBar(
                  visible: _selectedPart != null &&
                      _selectedWorkoutIds.isNotEmpty,
                  count: _selectedWorkoutIds.length,
                  onPressed: _confirmAddSelected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme) {
    if (_selectedPart != null) {
      return _WorkoutStepList(
        workouts: _matchingWorkouts,
        selectedWorkoutIds: _selectedWorkoutIds,
        onToggle: _toggleWorkoutSelection,
        onEdit: _openEditWorkout,
      );
    }
    if (_selectedGroup != null) {
      return _PartsStepList(
        parts: _availableParts,
        onPick: _selectPart,
      );
    }
    return _GroupsStepList(
      groups: _availableGroups,
      onPick: _selectGroup,
    );
  }
}

/// Drawer header — title + (optional) back button + close button.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.title,
    required this.canGoBack,
    required this.onBack,
    required this.onClose,
  });

  final String title;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: canGoBack ? onBack : null,
          ),
          const Gap(AppSpacing.xs),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// Step 1 — parent muscle groups.
class _GroupsStepList extends StatelessWidget {
  const _GroupsStepList({required this.groups, required this.onPick});

  final List<MajorMuscleGroup> groups;
  final ValueChanged<MajorMuscleGroup> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (groups.isEmpty) {
      return _EmptyMessage(
        icon: Icons.search_off_rounded,
        title: 'No workouts yet',
        message: 'Add workouts to your sessions to filter them here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      itemCount: groups.length,
      separatorBuilder: (_, _) => const Gap(AppSpacing.xs),
      itemBuilder: (context, index) {
        final g = groups[index];
        return Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.55,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onPick(g),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      g.icon,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: Text(
                      g.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
      },
    );
  }
}

/// Step 2 — specific body parts inside the chosen parent group.
class _PartsStepList extends StatelessWidget {
  const _PartsStepList({required this.parts, required this.onPick});

  final List<BodyPart> parts;
  final ValueChanged<BodyPart> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (parts.isEmpty) {
      return _EmptyMessage(
        icon: Icons.search_off_rounded,
        title: 'No workouts in this group',
        message: 'Try a different muscle group.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      itemCount: parts.length,
      separatorBuilder: (_, _) => const Gap(AppSpacing.xs),
      itemBuilder: (context, index) {
        final p = parts[index];
        return Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.55,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onPick(p),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      p.icon,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: Text(
                      p.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
      },
    );
  }
}

/// Step 3 — list of workouts matching the chosen body part. The
/// bottom action bar pops the drawer with the selected list, so the
/// card itself never pops directly.
class _WorkoutStepList extends StatelessWidget {
  const _WorkoutStepList({
    required this.workouts,
    required this.selectedWorkoutIds,
    required this.onToggle,
    required this.onEdit,
  });

  final List<Workout> workouts;
  final Set<int> selectedWorkoutIds;
  final ValueChanged<int> onToggle;
  final ValueChanged<Workout> onEdit;

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return _EmptyMessage(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'No workouts target this muscle group yet.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      itemCount: workouts.length,
      separatorBuilder: (_, _) => const Gap(AppSpacing.xs),
      itemBuilder: (context, index) {
        final w = workouts[index];
        final isSelected = selectedWorkoutIds.contains(w.workoutId);
        return AppWorkoutCard(
          workout: w,
          position: w.position,
          leading: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(w.workoutId),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
          ),
          onTap: () => onToggle(w.workoutId),
          // Edit only — Delete would operate on the workout's
          // original session, which this filter flow opts out of.
          trailing: _FilterWorkoutTrailing(onEdit: () => onEdit(w)),
        );
      },
    );
  }
}

/// Edit-only 3-dot menu — Delete would mutate the workout's
/// original session, which the filter flow is intentionally outside
/// of.
class _FilterWorkoutTrailing extends StatelessWidget {
  const _FilterWorkoutTrailing({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<_FilterWorkoutAction>(
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      tooltip: '',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      onSelected: (_) => onEdit(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _FilterWorkoutAction.edit,
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const Gap(AppSpacing.sm),
              const Text(
                'Edit',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _FilterWorkoutAction { edit }

/// Mirrors the bottom "Add N workout(s) for Today's Session" bar in
/// `SessionDetailsPage`. The user confirms their filter selection
/// here, which pops the drawer with that list so the caller can add
/// them to today's session.
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.visible,
    required this.count,
    required this.onPressed,
  });

  final bool visible;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              count == 1
                  ? "Add 1 workout for Today's Session"
                  : "Add $count workouts for Today's Session",
            ),
          ),
        ),
      ),
    );
  }
}

/// Small empty-state row used inside the drawer when a level has no
/// entries — keeps the user oriented instead of showing an empty
/// white surface.
class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const Gap(AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
