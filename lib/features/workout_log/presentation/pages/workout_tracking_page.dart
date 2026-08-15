import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../workout/domain/entities/body_part.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/presentation/bloc/workout_list_bloc.dart';
import '../../../workout/presentation/widgets/body_part_picker_sheet.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../bloc/workout_tracking_bloc.dart';

/// Today's tracking screen for a single workout.
///
/// Renders one tracking card with `Sets / Reps / Weight / Duration` for
/// the active workout. The card is pre-filled with the most recent
/// prior recorded values (or the template defaults on first open).
/// Saving only writes to today's `WorkoutLog` row — the session
/// template is never mutated.
class WorkoutTrackingPage extends StatelessWidget {
  const WorkoutTrackingPage({
    required this.sessionId,
    required this.workoutId,
    super.key,
  });

  final int sessionId;
  final int workoutId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkoutListBloc>(
      create: (_) =>
          getIt<WorkoutListBloc>()..add(WatchWorkoutsEvent(sessionId)),
      child: _WorkoutTrackingView(sessionId: sessionId, workoutId: workoutId),
    );
  }
}

class _WorkoutTrackingView extends StatelessWidget {
  const _WorkoutTrackingView({
    required this.sessionId,
    required this.workoutId,
  });

  final int sessionId;
  final int workoutId;

  Workout? _findWorkout(WorkoutListLoaded state) {
    for (final w in state.workouts) {
      if (w.id == workoutId) return w;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutListBloc, WorkoutListState>(
      builder: (context, listState) {
        if (listState is! WorkoutListLoaded) {
          return AppScaffold(title: '', body: const AppLoadingIndicator());
        }
        final workout = _findWorkout(listState);
        if (workout == null) {
          return AppScaffold(
            title: '',
            body: AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'Workout not found',
              message: 'This workout is no longer part of the session.',
            ),
          );
        }
        return BlocProvider<WorkoutTrackingBloc>(
          create: (_) => getIt<WorkoutTrackingBloc>()
            ..add(InitTrackingEvent(sessionId: sessionId, workout: workout)),
          child: _Body(workout: workout),
        );
      },
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.workout});

  final Workout workout;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  // Holds the body-part selection made on this screen. Initialised
  // from the workout template so a fresh open shows the saved value.
  // The save ✓ button forwards this value (not the template value)
  // so editing the body part here actually persists the change.
  BodyPart? _selectedBodyPart;

  @override
  void initState() {
    super.initState();
    _selectedBodyPart = widget.workout.targetedBodyPart;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workout = widget.workout;

    return AppScaffold(
      title: workout.exerciseName,
      actions: [
        BlocBuilder<WorkoutTrackingBloc, WorkoutTrackingState>(
          builder: (context, state) {
            // Save is only enabled once today's entry exists — before
            // that, there's nothing meaningful to save.
            final canSave =
                state is WorkoutTrackingLoaded && state.entry != null;
            return IconButton(
              tooltip: l10n.commonSave,
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: canSave
                      ? AppTheme.freshGradient
                      : LinearGradient(
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: canSave
                      ? const [
                          BoxShadow(
                            color: Color(0x4034D399),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.check_rounded,
                  color: canSave
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              onPressed: canSave
                  ? () {
                      // Mirror the just-edited values into the workout
                      // template (defaults) so the Session card reflects
                      // them on return. Otherwise the entry's edits
                      // only land in today's WorkoutLog row and the
                      // session's WorkoutCard stays stale.
                      // `canSave` ensures entry is non-null here.
                      final entry = state.entry!;
                      final w = state.workout;
                      context.read<WorkoutListBloc>().add(
                        UpdateWorkoutEvent(
                          id: w.id,
                          exerciseName: w.exerciseName,
                          defaultSets: entry.sets ?? w.defaultSets,
                          defaultReps: entry.reps ?? w.defaultReps,
                          defaultDurationSeconds:
                              entry.durationSeconds ?? w.defaultDurationSeconds,
                          defaultWeight: entry.weight ?? w.defaultWeight,
                          notes: w.notes,
                          // Use the body-part picked on this screen (if
                          // the user changed it), otherwise carry the
                          // template value through unchanged.
                          targetedBodyPart:
                              _selectedBodyPart ?? w.targetedBodyPart,
                        ),
                      );
                      context.pop();
                    }
                  : null,
            );
          },
        ),
      ],
      body: BlocConsumer<WorkoutTrackingBloc, WorkoutTrackingState>(
        listener: (context, state) {
          if (state is WorkoutTrackingDeleted) {
            context.pop();
          }
        },
        builder: (context, state) {
          if (state is WorkoutTrackingInitial ||
              state is WorkoutTrackingLoading) {
            return const AppLoadingIndicator();
          }
          if (state is WorkoutTrackingError) {
            return AppErrorView(
              failure: state.failure,
              onRetry: () => context.read<WorkoutTrackingBloc>().add(
                InitTrackingEvent(
                  sessionId: workout.sessionId,
                  workout: workout,
                ),
              ),
            );
          }
          if (state is WorkoutTrackingLoaded) {
            final entry = state.entry;
            if (entry == null) {
              return const AppLoadingIndicator();
            }
            return _SingleCardLayout(
              workout: workout,
              entry: entry,
              selectedBodyPart: _selectedBodyPart,
              onBodyPartChanged: (part) {
                setState(() {
                  _selectedBodyPart = part;
                });
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Gradient hero + single editable card layout.
class _SingleCardLayout extends StatelessWidget {
  const _SingleCardLayout({
    required this.workout,
    required this.entry,
    required this.selectedBodyPart,
    required this.onBodyPartChanged,
  });

  final Workout workout;
  final WorkoutLogEntry entry;
  final BodyPart? selectedBodyPart;
  final ValueChanged<BodyPart?> onBodyPartChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        _SummaryHero(workout: workout, entry: entry, bodyPart: selectedBodyPart),
        const Gap(AppSpacing.md),
        _TrackingCard(
          workout: workout,
          entry: entry,
          selectedBodyPart: selectedBodyPart,
          onBodyPartChanged: onBodyPartChanged,
        ),
      ],
    );
  }
}

/// Gradient hero with workout summary stats and the body-part chip.
class _SummaryHero extends StatelessWidget {
  const _SummaryHero({
    required this.workout,
    required this.entry,
    required this.bodyPart,
  });

  final Workout workout;
  final WorkoutLogEntry entry;
  final BodyPart? bodyPart;

  /// Displays [seconds] as minutes. We always render whole minutes in
  /// the UI; the bloc stores seconds canonically.
  String _formatDuration(int seconds) {
    final m = (seconds / 60).round();
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bodyPart != null) ...[
                      Icon(bodyPart!.icon, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      (bodyPart?.label ?? 'TRACKING').toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            workout.exerciseName,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),
          if (workout.notes.isNotEmpty) ...[
            const Gap(AppSpacing.xs),
            Text(
              workout.notes,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Gap(AppSpacing.lg),
          Row(
            children: [
              _HeroStat(
                label: 'SETS',
                value: entry.sets?.toString() ?? '—',
                icon: Icons.format_list_numbered_rounded,
              ),
              const Gap(AppSpacing.sm),
              _HeroStat(
                label: 'REPS',
                value: entry.reps?.toString() ?? '—',
                icon: Icons.repeat_rounded,
              ),
              const Gap(AppSpacing.sm),
              _HeroStat(
                label: 'WEIGHT',
                value: entry.weight == null
                    ? '—'
                    : entry.weight == entry.weight!.roundToDouble()
                        ? '${entry.weight!.toInt()}'
                        : entry.weight!.toStringAsFixed(1),
                icon: Icons.fitness_center_rounded,
              ),
              const Gap(AppSpacing.sm),
              _HeroStat(
                label: 'TIME',
                value: entry.durationSeconds == null
                    ? '—'
                    : _formatDuration(entry.durationSeconds!),
                icon: Icons.timer_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single tracking card containing the four editable fields. All edits
/// dispatch `UpsertTodayEntryEvent` and stream back via the bloc.
class _TrackingCard extends StatelessWidget {
  const _TrackingCard({
    required this.workout,
    required this.entry,
    required this.selectedBodyPart,
    required this.onBodyPartChanged,
  });

  final Workout workout;
  final WorkoutLogEntry entry;
  final BodyPart? selectedBodyPart;
  final ValueChanged<BodyPart?> onBodyPartChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    void upsert({int? sets, int? reps, double? weight, int? durationSeconds}) {
      context.read<WorkoutTrackingBloc>().add(
        UpsertTodayEntryEvent(
          sets: sets,
          reps: reps,
          weight: weight,
          durationSeconds: durationSeconds,
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.freshGradient,
                    borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: Text(
                    "TODAY'S RECORD",
                    style: AppSectionHeader.titleStyle(theme),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete today\'s record',
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                      size: 18,
                    ),
                  ),
                  onPressed: () => context.read<WorkoutTrackingBloc>().add(
                    const DeleteTodayEntryEvent(),
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.md),
            // Targeted Body Part field — tapping opens the bottom-sheet
            // picker. Selection is held in `_BodyState`; on ✓ save it
            // is forwarded to `UpdateWorkoutEvent.targetedBodyPart` so
            // the workout template (and Session card) reflects it.
            Material(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.md),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  final picked = await BodyPartPickerSheet.show(
                    context,
                    initial: selectedBodyPart,
                  );
                  if (!context.mounted) return;
                  // The picker returns null both for "user dismissed" and
                  // "user tapped Clear". We treat any return as an
                  // explicit choice and propagate it so the next save
                  // reflects the user's intent.
                  onBodyPartChanged(picked);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: selectedBodyPart != null
                              ? theme.colorScheme.primary.withValues(alpha: 0.14)
                              : theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          selectedBodyPart?.icon ??
                              Icons.add_circle_outline_rounded,
                          size: 18,
                          color: selectedBodyPart != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.workoutFieldTargetedBodyPart
                                  .toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              selectedBodyPart?.label ??
                                  l10n.workoutTargetedBodyPartEmpty,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                                color: selectedBodyPart != null
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
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
            ),
            const Gap(AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _NumericField(
                    label: 'Sets',
                    initialValue: entry.sets?.toString() ?? '',
                    icon: Icons.format_list_numbered_rounded,
                    suffix: 'reps',
                    onChanged: (text) {
                      upsert(
                        sets: text.trim().isEmpty
                            ? null
                            : int.tryParse(text.trim()),
                      );
                    },
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: _NumericField(
                    label: 'Reps',
                    initialValue: entry.reps?.toString() ?? '',
                    icon: Icons.repeat_rounded,
                    onChanged: (text) {
                      upsert(
                        reps: text.trim().isEmpty
                            ? null
                            : int.tryParse(text.trim()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _NumericField(
                    label: 'Weight',
                    initialValue: entry.weight == null
                        ? ''
                        : entry.weight == entry.weight!.roundToDouble()
                            ? entry.weight!.toInt().toString()
                            : entry.weight!.toString(),
                    icon: Icons.fitness_center_rounded,
                    suffix: 'kg',
                    onChanged: (text) {
                      upsert(
                        weight: text.trim().isEmpty
                            ? null
                            : double.tryParse(text.trim()),
                      );
                    },
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: _NumericField(
                    label: 'Duration',
                    initialValue: entry.durationSeconds == null
                        ? ''
                        : (entry.durationSeconds! / 60).round().toString(),
                    icon: Icons.timer_outlined,
                    suffix: 'min',
                    onChanged: (text) {
                      upsert(
                        durationSeconds: text.trim().isEmpty
                            ? null
                            : (double.tryParse(text.trim()) == null
                                  ? null
                                  : (double.parse(text.trim()) * 60).round()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NumericField extends StatefulWidget {
  const _NumericField({
    required this.label,
    required this.initialValue,
    required this.icon,
    required this.onChanged,
    this.suffix,
  });

  final String label;
  final String initialValue;
  final IconData icon;
  final String? suffix;
  final ValueChanged<String> onChanged;

  @override
  State<_NumericField> createState() => _NumericFieldState();
}

class _NumericFieldState extends State<_NumericField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon, size: 20),
        suffixText: widget.suffix,
        suffixStyle: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}
