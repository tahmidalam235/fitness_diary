import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/workout_dao.dart';
import '../../../../core/di/injection.dart';
import '../../../workout/presentation/bloc/workout_bloc.dart';
import '../../../workout/presentation/bloc/workout_event.dart';
import '../../../workout/presentation/bloc/workout_state.dart';

class SessionDetailsPage extends StatelessWidget {
  const SessionDetailsPage({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WorkoutBloc(getIt<WorkoutDao>())
            ..add(LoadWorkoutsBySession(session.id!)),
      child: _SessionDetailsView(session: session),
    );
  }
}

class _SessionDetailsView extends StatelessWidget {
  const _SessionDetailsView({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(session.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO(Tahmid): Navigate to AddWorkoutPage
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Workout'),
      ),
      body: BlocBuilder<WorkoutBloc, WorkoutState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.workouts.isEmpty) {
            return const Center(child: Text('No workouts added yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.workouts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final workout = state.workouts[index];

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.fitness_center),
                  ),
                  title: Text(workout.exerciseName),
                  subtitle: Text(
                    '${workout.sets} Sets • '
                    '${workout.reps} Reps • '
                    '${workout.weight} kg',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      context.read<WorkoutBloc>().add(
                        DeleteWorkout(workout.id),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
