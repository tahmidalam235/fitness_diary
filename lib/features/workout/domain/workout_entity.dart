class WorkoutEntity {
  const WorkoutEntity({
    this.id,
    required this.sessionId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  final int? id;
  final int sessionId;
  final String exerciseName;
  final int sets;
  final int reps;
  final double weight;
}
