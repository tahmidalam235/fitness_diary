import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/body_part.dart';
import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

class UpdateWorkoutParams {
  const UpdateWorkoutParams({
    required this.id,
    required this.exerciseName,
    required this.defaultSets,
    required this.defaultReps,
    this.defaultDurationSeconds,
    this.defaultWeight,
    this.notes = '',
    this.targetedBodyPart,
  });

  final int id;
  final String exerciseName;
  final int defaultSets;
  final int defaultReps;
  final int? defaultDurationSeconds;
  final double? defaultWeight;
  final String notes;
  final BodyPart? targetedBodyPart;
}

class UpdateWorkout extends UseCase<Workout, UpdateWorkoutParams> {
  const UpdateWorkout({required this.repository});

  final WorkoutRepository repository;

  @override
  Future<Either<Failure, Workout>> call(UpdateWorkoutParams params) {
    final trimmedName = params.exerciseName.trim();
    if (trimmedName.length < 2) {
      return Future.value(
        const Left(
          ValidationFailure(
            message: 'Workout name must be at least 2 characters',
            errors: {
              'exerciseName': 'Workout name must be at least 2 characters',
            },
          ),
        ),
      );
    }
    if (params.defaultSets < 1 || params.defaultSets > 50) {
      return Future.value(
        const Left(
          ValidationFailure(
            message: 'Sets must be between 1 and 50',
            errors: {'defaultSets': 'Sets must be between 1 and 50'},
          ),
        ),
      );
    }
    if (params.defaultReps < 1 || params.defaultReps > 1000) {
      return Future.value(
        const Left(
          ValidationFailure(
            message: 'Reps must be between 1 and 1000',
            errors: {'defaultReps': 'Reps must be between 1 and 1000'},
          ),
        ),
      );
    }

    return repository.updateWorkout(
      id: params.id,
      exerciseName: trimmedName,
      defaultSets: params.defaultSets,
      defaultReps: params.defaultReps,
      defaultDurationSeconds: params.defaultDurationSeconds,
      defaultWeight: params.defaultWeight,
      notes: params.notes.trim(),
      targetedBodyPart: params.targetedBodyPart,
    );
  }
}
