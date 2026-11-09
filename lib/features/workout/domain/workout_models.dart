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

/// What the finish screen celebrates; built from the session just before it is finished.
class WorkoutResult {
  const WorkoutResult({
    required this.workoutId,
    required this.name,
    required this.duration,
    required this.sets,
    required this.exercises,
    required this.volumeKg,
    this.records = const [],
  });

  factory WorkoutResult.fromSession(WorkoutSession s, DateTime now, {List<String> records = const []}) {
    final done = [for (final b in s.blocks) b.sets.where((x) => x.completed).toList()];
    return WorkoutResult(
      workoutId: s.workout.id,
      name: s.workout.name,
      duration: now.difference(s.workout.startedAt),
      sets: done.fold(0, (n, l) => n + l.length),
      exercises: done.where((l) => l.isNotEmpty).length,
      volumeKg: done.expand((l) => l).fold(0.0, (v, x) => v + x.weightKg * x.reps),
      records: records,
    );
  }

  final int workoutId;
  final String name;
  final Duration duration;
  final int sets, exercises;
  final double volumeKg;

  /// Names of exercises whose personal record was beaten.
  final List<String> records;
}
