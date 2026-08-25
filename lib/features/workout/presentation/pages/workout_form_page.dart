import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../domain/entities/workout.dart';
import '../bloc/workout_list_bloc.dart';
import '../widgets/workout_form.dart';

/// Page for creating or editing a workout attached to a session.
///
/// When [workoutId] is non-null the form pre-loads the existing workout
/// (looked up from the bloc's loaded list) and dispatches
/// [UpdateWorkoutEvent] on submit; otherwise it dispatches
/// [AddWorkoutEvent] for the [sessionId].
///
/// The submit flow awaits the bloc's mutation completion before popping
/// so the parent screen sees the updated state on return.
class WorkoutFormPage extends StatelessWidget {
  const WorkoutFormPage({required this.sessionId, this.workoutId, super.key});

  final int sessionId;
  final int? workoutId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkoutListBloc>(
      create: (_) =>
          getIt<WorkoutListBloc>()..add(WatchWorkoutsEvent(sessionId)),
      child: _WorkoutFormView(sessionId: sessionId, workoutId: workoutId),
    );
  }
}

class _WorkoutFormView extends StatelessWidget {
  const _WorkoutFormView({required this.sessionId, required this.workoutId});

  final int sessionId;
  final int? workoutId;

  bool get _isEditing => workoutId != null;

  Workout? _findInitial(WorkoutListLoaded state) {
    if (workoutId == null) return null;
    for (final w in state.workouts) {
      if (w.id == workoutId) return w;
    }
    return null;
  }

  Future<void> _onSubmit(BuildContext context, WorkoutFormResult result) async {
    final bloc = context.read<WorkoutListBloc>();
    // Capture the current state to wait for the mutation cycle to finish.
    final completer = Completer<void>();
    late final StreamSubscription<WorkoutListState> sub;
    sub = bloc.stream.listen((state) {
      // The form considers the operation "done" when either the bloc
      // emits an error, or it emits a Loaded state that is not currently
      // mutating. Both are terminal outcomes for this single add/update.
      if (state is WorkoutListLoaded && !state.isMutating) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete();
      } else if (state is WorkoutListError) {
        sub.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    if (_isEditing) {
      bloc.add(
        UpdateWorkoutEvent(
          id: workoutId!,
          exerciseName: result.exerciseName,
          defaultSets: result.defaultSets,
          defaultReps: result.defaultReps,
          defaultDurationSeconds: result.defaultDurationSeconds,
          defaultWeight: result.defaultWeight,
          notes: result.notes,
          targetedBodyPart: result.targetedBodyPart,
        ),
      );
    } else {
      bloc.add(
        AddWorkoutEvent(
          sessionId: sessionId,
          exerciseName: result.exerciseName,
          defaultSets: result.defaultSets,
          defaultReps: result.defaultReps,
          defaultDurationSeconds: result.defaultDurationSeconds,
          defaultWeight: result.defaultWeight,
          notes: result.notes,
          targetedBodyPart: result.targetedBodyPart,
        ),
      );
    }

    // Wait for the bloc to finish writing to Drift (MutationFinished),
    // so the parent screen's reactive stream has already received the
    // updated snapshot before we pop.
    await completer.future;

    if (!context.mounted) return;
    final state = bloc.state;
    final messenger = ScaffoldMessenger.of(context);
    if (state is WorkoutListError) {
      // The data source throws a `ValidationException` when the user
      // tries to add a workout whose name matches an existing one in
      // this session; the repository then wraps it in a
      // `DatabaseException`. Detect that specific case and show a clean
      // user-facing message instead of the technical stack.
      final isDuplicate = state.failure.message.contains('already exists');
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isDuplicate
                  ? 'This workout already exists in this session.'
                  : 'Could not save workout:\n${state.failure.message}',
            ),
            duration: Duration(seconds: isDuplicate ? 4 : 8),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    // Success: confirm with the user and pop. We DON'T pop on error so
    // the user can adjust the form and retry.
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Workout updated' : 'Workout added'),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _isEditing ? l10n.workoutEditTitle : l10n.workoutAddTitle;
    final theme = Theme.of(context);

    return AppScaffold(
      title: title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Premium gradient hero header with the workout name + an
          // icon, so the "opening UI" reads as polished and intentional
          // rather than a plain AppBar with a form below.
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
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
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _isEditing
                        ? Icons.edit_rounded
                        : Icons.add_circle_outline_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _isEditing
                            ? 'Update the defaults for this workout'
                            : 'Define the defaults for this workout template',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<WorkoutListBloc, WorkoutListState>(
              builder: (context, state) {
                final initial = state is WorkoutListLoaded
                    ? _findInitial(state)
                    : null;
                // Fix edit-populate: the previous key resolved to the
                // same `workoutId` before AND after the bloc loaded, so
                // the form was never recreated when the initial values
                // arrived — controllers kept their empty defaults. The
                // suffix flips once the workout is found, forcing one
                // rebuild with populated fields. New-workout (no
                // workoutId) keeps the original key.
                final key = workoutId == null
                    ? ValueKey('new')
                    : ValueKey(
                        'edit-$workoutId-${initial != null ? 'loaded' : 'pending'}',
                      );
                return WorkoutForm(
                  key: key,
                  initial: initial,
                  onSubmit: (result) => _onSubmit(context, result),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
