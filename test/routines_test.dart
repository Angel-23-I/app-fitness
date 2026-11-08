import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/core/db/app_database.dart';
import 'package:fittrack/features/routines/data/routine_repository.dart';
import 'package:fittrack/features/routines/domain/routine_models.dart';

void main() {
  late AppDatabase db;
  late RoutineRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = RoutineRepository(db);
  });
  tearDown(() => db.close());

  test('seeds about 40 exercises', () async {
    expect((await db.select(db.exercises).get()).length, greaterThanOrEqualTo(40));
  });

  test('saves routine keeping order, then replaces it on edit', () async {
    final ex = await db.select(db.exercises).get();
    final id = await repo.save(
        name: 'Push', items: [RoutineItem(ex[2], sets: 4), RoutineItem(ex[0]), RoutineItem(ex[1])]);

    var d = (await repo.load(id))!;
    expect(d.items.map((e) => e.exercise.id), [ex[2].id, ex[0].id, ex[1].id]);
    expect(d.items.first.sets, 4);

    await repo.save(id: id, name: 'Push 2', items: [RoutineItem(ex[1])]);
    d = (await repo.load(id))!;
    expect(d.routine.name, 'Push 2');
    expect(d.items.length, 1);

    final list = await repo.watchAll().first;
    expect(list.single.exerciseCount, 1);

    await repo.delete(id);
    expect(await repo.load(id), isNull);
  });
}
