import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import 'package:fitness_diary/features/today/presentation/bloc/today_workouts_bloc.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/data/datasources/workout_local_datasource.dart';
import '../../../workout/presentation/bloc/workout_list_bloc.dart';
import '../../../workout/presentation/widgets/workout_card.dart';
import '../../../workout_log/domain/entities/workout_log_entry.dart';
import '../../../workout_log/domain/usecases/add_workouts_to_today.dart';
import '../../../workout_log/domain/usecases/get_last_entries_for_workouts.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';

/// Session detail view: lists the workouts attached to this session and
/// supports editing / deleting the session itself.
class SessionDetailsPage extends StatelessWidget {
  const SessionDetailsPage({
    required this.sessionId,
    this.autoEnterSelectMode = false,
    super.key,
  });

  final int sessionId;

  /// When true, the page boots straight into select mode. Used by the
  /// Today page's empty state so the user lands on the picker without
  /// having to tap "Select" first.
  final bool autoEnterSelectMode;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>(
          create: (_) =>
              getIt<SessionBloc>()..add(GetSessionByIdEvent(sessionId)),
        ),
        BlocProvider<WorkoutListBloc>(
          create: (_) =>
              getIt<WorkoutListBloc>()..add(WatchWorkoutsEvent(sessionId)),
        ),
        BlocProvider<TodayWorkoutsBloc>(
          create: (_) =>
              getIt<TodayWorkoutsBloc>()
                ..add(WatchTodayWorkoutsEvent(sessionId)),
        ),
      ],
      child: _SessionDetailsView(
        sessionId: sessionId,
        autoEnterSelectMode: autoEnterSelectMode,
      ),
    );
  }
}

class _SessionDetailsView extends StatefulWidget {
  const _SessionDetailsView({
    required this.sessionId,
    required this.autoEnterSelectMode,
  });

  final int sessionId;
  final bool autoEnterSelectMode;

  @override
  State<_SessionDetailsView> createState() => _SessionDetailsViewState();
}

class _SessionDetailsViewState extends State<_SessionDetailsView> {
  /// Selected master workout ids for today's session. The user toggles
  /// these via the checkbox on each `WorkoutCard`.
  final Set<int> _selected = <int>{};

  /// When true, each workout card shows a checkbox and tapping the
  /// card body toggles selection instead of navigating. Toggling this
  /// off resets any pending selection.
  bool _selectMode = false;

  bool get _hasSelection => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.autoEnterSelectMode) {
      _selectMode = true;
    }
  }

  void _toggle(int masterWorkoutId) {
    setState(() {
      if (_selected.contains(masterWorkoutId)) {
        _selected.remove(masterWorkoutId);
      } else {
        _selected.add(masterWorkoutId);
      }
    });
  }

  void _enterSelectMode() {
    if (_selectMode) return;
    setState(() => _selectMode = true);
  }

  void _exitSelectMode() {
    if (!_selectMode && _selected.isEmpty) return;
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  Future<void> _addForToday(List<Workout> workouts) async {
    final selected = workouts
        .where((w) => _selected.contains(w.workoutId))
        .toList(growable: false);
    if (selected.isEmpty) return;

    // Resolve each picked Workout's masterFirestoreId so the today
    // page can join entries back to workout templates even if the int
    // `workoutId` hashes don't agree across snapshots. The
    // `Workout` entity doesn't carry the Firestore id, so we look it
    // up via the local data source (which mirrors Firestore).
    final idMap = await getIt<WorkoutLocalDataSource>().getAllWorkoutIds();

    // Prefill from the most recent prior entry per selected workout,
    // falling back to the template defaults when there's no history.
    final lastResult = await getIt<GetLastEntriesForWorkouts>()(
      selected.map((w) => w.workoutId).toList(),
    );
    final priorByWorkout = lastResult.fold(
      (failure) => const <int, WorkoutLogEntry>{},
      (map) => map,
    );

    final entries = <WorkoutLogEntry>[
      for (final w in selected)
        () {
          final prior = priorByWorkout[w.workoutId];
          return WorkoutLogEntry(
            id: 0,
            workoutLogId: 0, // overwritten by the repository
            workoutId: w.workoutId,
            setIndex: 1,
            position: 0,
            sets: prior?.sets ?? w.defaultSets,
            reps: prior?.reps ?? w.defaultReps,
            weight: prior?.weight ?? w.defaultWeight,
            durationSeconds: prior?.durationSeconds ?? w.defaultDurationSeconds,
            workoutFirestoreId: idMap[w.workoutId],
          );
        }(),
    ];

    final addResult = await getIt<AddWorkoutsToToday>()(
      AddWorkoutsToTodayParams(sessionId: widget.sessionId, entries: entries),
    );

    if (!mounted) return;
    addResult.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) {
        _exitSelectMode();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Added to today's session")),
        );
        context.goNamed(
          RouteNames.today,
          queryParameters: {'sessionId': widget.sessionId.toString()},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();

    return AppScaffold(
      title: l10n.sessionDetailsTitle,
      actions: [
        if (_selectMode)
          TextButton.icon(
            onPressed: _exitSelectMode,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancel'),
          )
        else
          BlocBuilder<WorkoutListBloc, WorkoutListState>(
            builder: (context, state) {
              // Hide the Select toggle only when we *know* there are no
              // workouts (Loaded with empty list, or a hard error). While
              // loading or in any other transitional state we still
              // surface the button so the user can find it.
              final hasNoWorkouts =
                  state is WorkoutListLoaded && state.workouts.isEmpty;
              if (hasNoWorkouts) return const SizedBox.shrink();
              return FilledButton.tonalIcon(
                onPressed: _enterSelectMode,
                icon: const Icon(Icons.checklist_rounded),
                label: const Text('Select'),
              );
            },
          ),
        BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) {
            final loaded = state is SessionLoaded
                ? state.selectedSession
                : null;
            if (loaded == null) {
              return const SizedBox.shrink();
            }
            return Row(
              children: [
                IconButton(
                  tooltip: l10n.commonEdit,
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => context.pushNamed(
                    RouteNames.sessionEdit,
                    pathParameters: {'id': loaded.id.toString()},
                  ),
                ),
                IconButton(
                  tooltip: l10n.commonDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, loaded.id!),
                ),
              ],
            );
          },
        ),
      ],
      bottomNavigationBar: BlocBuilder<WorkoutListBloc, WorkoutListState>(
        builder: (context, state) {
          if (!_selectMode) return const SizedBox.shrink();
          if (!_hasSelection) return const SizedBox.shrink();
          if (state is! WorkoutListLoaded) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: FilledButton.icon(
                onPressed: () => _addForToday(state.workouts),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _selected.length == 1
                      ? 'Add 1 workout for Today\'s Session'
                      : 'Add ${_selected.length} workouts for Today\'s Session',
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<WorkoutListBloc, WorkoutListState>(
        builder: (context, state) {
          if (state is! WorkoutListLoaded) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            heroTag: 'session-add-workout',
            onPressed: () => context.pushNamed(
              RouteNames.workoutNew,
              pathParameters: {'id': widget.sessionId.toString()},
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.workoutListEmptyAction),
          );
        },
      ),
      body: BlocConsumer<SessionBloc, SessionState>(
        listenWhen: (prev, curr) =>
            prev is! SessionError && curr is SessionError,
        listener: (context, state) {
          if (state is SessionError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.failure.message)));
          }
        },
        builder: (context, state) {
          if (state is SessionLoading) {
            return const AppLoadingIndicator();
          }
          if (state is SessionError) {
            final isNotFound = state.failure is NotFoundFailure;
            if (isNotFound) {
              return Center(child: Text(l10n.sessionDetailsNotFound));
            }
            return AppErrorView(
              failure: state.failure,
              onRetry: () => context.read<SessionBloc>().add(
                GetSessionByIdEvent(widget.sessionId),
              ),
            );
          }
          if (state is SessionLoaded) {
            final session = state.selectedSession;
            if (session == null) {
              return const AppLoadingIndicator();
            }
            return _buildBody(
              context,
              sessionName: session.name,
              description: session.description,
              createdAt: session.createdAt,
              updatedAt: session.updatedAt,
              theme: theme,
              l10n: l10n,
              dateFormat: dateFormat,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required String sessionName,
    required String description,
    required DateTime createdAt,
    required DateTime updatedAt,
    required ThemeData theme,
    required AppLocalizations l10n,
    required DateFormat dateFormat,
  }) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sessionName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const Gap(AppSpacing.xs),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                  const Gap(AppSpacing.sm),
                  Text(
                    l10n.sessionDetailsCreatedAt(dateFormat.format(createdAt)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const Gap(AppSpacing.xxs),
                  Text(
                    l10n.sessionDetailsUpdatedAt(dateFormat.format(updatedAt)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        BlocConsumer<WorkoutListBloc, WorkoutListState>(
          listenWhen: (prev, curr) =>
              prev is! WorkoutListError && curr is WorkoutListError,
          listener: (context, state) {
            if (state is WorkoutListError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.failure.message)));
            }
          },
          builder: (context, state) {
            if (state is WorkoutListLoading) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadingIndicator(),
              );
            }
            if (state is WorkoutListError) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: AppErrorView(
                  failure: state.failure,
                  onRetry: () => context.read<WorkoutListBloc>().add(
                    WatchWorkoutsEvent(widget.sessionId),
                  ),
                ),
              );
            }
            if (state is WorkoutListLoaded) {
              return BlocBuilder<TodayWorkoutsBloc, TodayWorkoutsState>(
                builder: (context, todayState) {
                  // Only render the list once we know which workouts are
                  // already tracked for today. This prevents the "tick
                  // mark flash" where already-picked workouts appear
                  // unticked for a few frames.
                  if (todayState is! TodayWorkoutsLoaded) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppLoadingIndicator(),
                    );
                  }

                  final trackedIds =
                      todayState.entries.map((e) => e.workoutId).toSet();

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _WorkoutListSection(
                        workouts: state.workouts,
                        sessionId: widget.sessionId,
                        selectedMasterWorkoutIds: _selected,
                        trackedWorkoutIds: trackedIds,
                        selectMode: _selectMode,
                        onToggleSelection: _toggle,
                      ),
                    ),
                  );
                },
              );
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SessionBloc>();
    final state = bloc.state;
    final name = state is SessionLoaded
        ? (state.selectedSession?.name ?? '')
        : '';

    final confirmed = await showConfirmDialog(
      context,
      title: l10n.sessionDeleteTitle,
      message: l10n.sessionDeleteMessage(name),
    );

    if (confirmed && context.mounted) {
      bloc.add(DeleteSessionEvent(id));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (context.mounted) {
        context.pop();
      }
    }
  }
}

class _WorkoutListSection extends StatelessWidget {
  const _WorkoutListSection({
    required this.workouts,
    required this.sessionId,
    required this.selectedMasterWorkoutIds,
    required this.trackedWorkoutIds,
    required this.selectMode,
    required this.onToggleSelection,
  });

  final List<Workout> workouts;
  final int sessionId;
  final Set<int> selectedMasterWorkoutIds;
  final Set<int> trackedWorkoutIds;
  final bool selectMode;
  final ValueChanged<int> onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (workouts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: AppEmptyState(
          title: l10n.workoutListEmptyTitle,
          message: l10n.workoutListEmptyMessage,
          icon: Icons.fitness_center_rounded,
          actionLabel: l10n.workoutListEmptyAction,
          onAction: () => context.pushNamed(
            RouteNames.workoutNew,
            pathParameters: {'id': sessionId.toString()},
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectMode) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const Gap(AppSpacing.xs),
                Expanded(
                  child: Text(
                    selectedMasterWorkoutIds.isEmpty
                        ? 'Tap the boxes to pick workouts for today'
                        : '${selectedMasterWorkoutIds.length} selected — tap "Add for Today\'s Session" below',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.sm),
        ] else
          const Gap(AppSpacing.sm),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: workouts.length,
          onReorderItem: (oldIndex, newIndex) {
            final ids = <int>[for (final w in workouts) w.id];
            final moved = ids.removeAt(oldIndex);
            ids.insert(newIndex, moved);
            context.read<WorkoutListBloc>().add(ReorderWorkoutsEvent(ids));
          },
          itemBuilder: (context, index) {
            final w = workouts[index];
            final isTracked = trackedWorkoutIds.contains(w.workoutId);
            final selected =
                selectedMasterWorkoutIds.contains(w.workoutId) || isTracked;

            return Padding(
              key: ValueKey<int>(w.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: WorkoutCard(
                workout: w,
                // Big, tappable checkbox appears only in select mode.
                leading: selectMode
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Checkbox(
                            value: selected,
                            onChanged: isTracked
                                ? null
                                : (_) => onToggleSelection(w.workoutId),
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                          ),
                        ),
                      )
                    : null,
                onTap: selectMode
                    ? (isTracked ? () {} : () => onToggleSelection(w.workoutId))
                    : () => context.pushNamed(
                        RouteNames.workoutTracking,
                        pathParameters: {
                          'id': sessionId.toString(),
                          'workoutId': w.id.toString(),
                        },
                      ),
                // Fix today→edit navigation: the Today page's
                // "Add Session" picker opens this page in select mode,
                // and previously the 3-dot menu's Edit action was a
                // no-op in that mode — tapping it did nothing. Allow
                // navigation to the edit page in both modes so the
                // user can manage a workout from the Today flow
                // without first having to back out of select mode.
                onEdit: () => context.pushNamed(
                  RouteNames.workoutEdit,
                  pathParameters: {
                    'id': sessionId.toString(),
                    'workoutId': w.id.toString(),
                  },
                ),
                onDelete: selectMode
                    ? () {}
                    : () => _confirmDelete(context, w.id, w.exerciseName),
                // Hide the drag handle in select mode so the checkbox has
                // room and reorder isn't accidentally triggered.
                dragHandle: selectMode
                    ? const SizedBox(width: AppSpacing.xs)
                    : ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpacing.xs),
                          child: Icon(Icons.drag_handle_rounded),
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id, String name) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.workoutDeleteTitle,
      message: l10n.workoutDeleteMessage(name),
    );
    if (confirmed && context.mounted) {
      context.read<WorkoutListBloc>().add(DeleteWorkoutEvent(id));
    }
  }
}
