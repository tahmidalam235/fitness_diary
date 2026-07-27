import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/daos/workout_dao.dart';
import '../../../../core/di/injection.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';

class WorkoutsPage extends StatelessWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WorkoutBloc(getIt<WorkoutDao>())..add(const LoadWorkouts()),
      child: const _WorkoutView(),
    );
  }
}

class _WorkoutView extends StatelessWidget {
  const _WorkoutView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Library')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<WorkoutBloc, WorkoutState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.workouts.isEmpty) {
            return const Center(child: Text('No Workouts'));
          }

          return ListView.builder(
            itemCount: state.workouts.length,
            itemBuilder: (context, index) {
              final workout = state.workouts[index];

              return ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(workout.exerciseName),
                subtitle: Text(
                  '${workout.sets} Sets • ${workout.reps} Reps • ${workout.weight} kg',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    context.read<WorkoutBloc>().add(DeleteWorkout(workout.id));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
