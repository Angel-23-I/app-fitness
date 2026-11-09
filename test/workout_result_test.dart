import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/core/db/app_database.dart';
import 'package:fittrack/core/db/enums.dart';
import 'package:fittrack/features/workout/domain/workout_models.dart';

void main() {
  Exercise exercise(int id) => Exercise(
      id: id, name: 'E$id', muscleGroup: MuscleGroup.chest, equipment: Equipment.barbell, isCustom: false);
  WorkoutSet set(int id, int exerciseId, double kg, int reps, bool done) => WorkoutSet(
      id: id,
      workoutId: 1,
      exerciseId: exerciseId,
      exerciseOrder: 0,
      setNumber: id,
      reps: reps,
      weightKg: kg,
      completed: done);

  test('WorkoutResult counts only completed sets', () {
    final start = DateTime(2026, 1, 1, 10);
    final session = WorkoutSession(Workout(id: 1, routineId: 1, name: 'Push', startedAt: start), [
      ExerciseBlock(exercise(1), [set(1, 1, 60, 8, true), set(2, 1, 60, 6, true), set(3, 1, 60, 5, false)]),
      ExerciseBlock(exercise(2), [set(4, 2, 20, 10, false)]),
      ExerciseBlock(exercise(3), [set(5, 3, 0, 15, true)]),
    ]);

    final r = WorkoutResult.fromSession(session, start.add(const Duration(minutes: 47)), records: ['E1']);

    expect(r.duration, const Duration(minutes: 47));
    expect(r.sets, 3);
    expect(r.exercises, 2);
    expect(r.volumeKg, 60 * 8 + 60 * 6);
    expect(r.records, ['E1']);
  });
}
