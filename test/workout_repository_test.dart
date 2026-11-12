import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/core/db/app_database.dart';
import 'package:fittrack/features/routines/data/routine_repository.dart';
import 'package:fittrack/features/routines/domain/routine_models.dart';
import 'package:fittrack/features/workout/data/workout_repository.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;
  late int routineId;
  late Exercise bench;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final routines = RoutineRepository(db);
    repo = WorkoutRepository(db, routines);
    bench = (await db.select(db.exercises).get()).first;
    routineId = await routines.save(name: 'Push', items: [RoutineItem(bench, sets: 2, reps: 8)]);
  });
  tearDown(() => db.close());

  Future<List<Exercise>> doWorkout(double kg, int reps) async {
    final id = await repo.startWorkout(routineId);
    final session = (await repo.watchSession(id).first)!;
    final first = session.blocks.single.sets.first;
    await repo.updateSet(first.id, weightKg: kg, reps: reps, completed: true);
    return repo.finish(id);
  }

  test('start creates pre-filled sets and resumes the open workout', () async {
    final id = await repo.startWorkout(routineId);
    expect(await repo.startWorkout(routineId), id);
    final s = (await repo.watchSession(id).first)!;
    expect(s.blocks.single.sets.length, 2);
    expect(s.blocks.single.sets.first.reps, 8);
  });

  test('finish keeps only completed sets; empty workouts are discarded', () async {
    await doWorkout(60, 8);
    final history = await repo.watchHistory().first;
    expect(history.single.sets, 1);
    expect(history.single.volumeKg, 480);

    final id = await repo.startWorkout(routineId);
    await repo.finish(id); // nothing completed
    expect((await repo.watchHistory().first).length, 1);
  });

  test('last performance prefills the next workout and PRs are detected', () async {
    expect(await doWorkout(60, 8), isEmpty); // first time is not a PR break
    final last = await repo.lastPerformance(bench.id);
    expect(last.single.weightKg, 60);

    final id = await repo.startWorkout(routineId);
    final s = (await repo.watchSession(id).first)!;
    expect(s.blocks.single.sets.first.weightKg, 60);
    await repo.discard(id);

    expect((await doWorkout(65, 8)).map((e) => e.id), [bench.id]);
    expect(await doWorkout(50, 5), isEmpty);
    expect((await repo.personalRecords())[bench.id]!.maxWeight, 65);
  });

  test('addExercises adds exercises to active workout and removeExerciseBlock removes them', () async {
    final id = await repo.startWorkout(routineId);
    final allEx = await db.select(db.exercises).get();
    final squat = allEx[1];
    await repo.addExercises(id, [squat]);

    var session = (await repo.watchSession(id).first)!;
    expect(session.blocks.length, 2);
    expect(session.blocks.last.exercise.id, squat.id);
    expect(session.blocks.last.sets.length, 3);

    await repo.removeExerciseBlock(id, session.blocks.last.sets.first.exerciseOrder);
    session = (await repo.watchSession(id).first)!;
    expect(session.blocks.length, 1);
  });

  test('deleteWorkout removes finished workout and its sets', () async {
    await doWorkout(60, 8);
    var history = await repo.watchHistory().first;
    expect(history.length, 1);

    await repo.deleteWorkout(history.first.workout.id);
    history = await repo.watchHistory().first;
    expect(history, isEmpty);
  });
}
