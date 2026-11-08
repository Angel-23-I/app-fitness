import '../../../core/db/app_database.dart';

class ExerciseBlock {
  const ExerciseBlock(this.exercise, this.sets);
  final Exercise exercise;
  final List<WorkoutSet> sets;
}

class WorkoutSession {
  const WorkoutSession(this.workout, this.blocks);
  final Workout workout;
  final List<ExerciseBlock> blocks;

  bool get hasCompletedSet => blocks.any((b) => b.sets.any((s) => s.completed));
}

class WorkoutSummary {
  const WorkoutSummary(this.workout, {required this.sets, required this.volumeKg});
  final Workout workout;
  final int sets;
  final double volumeKg;

  Duration get duration => (workout.endedAt ?? workout.startedAt).difference(workout.startedAt);
}
