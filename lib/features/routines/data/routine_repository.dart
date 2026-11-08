import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../domain/routine_models.dart';

class RoutineRepository {
  RoutineRepository(this._db);
  final AppDatabase _db;

  Stream<List<RoutineSummary>> watchAll() {
    final count = _db.routineExercises.id.count();
    final q = _db.select(_db.routines).join([
      leftOuterJoin(_db.routineExercises,
          _db.routineExercises.routineId.equalsExp(_db.routines.id)),
    ])
      ..addColumns([count])
      ..groupBy([_db.routines.id])
      ..orderBy([OrderingTerm.asc(_db.routines.name)]);
    return q.watch().map((rows) => [
          for (final r in rows) RoutineSummary(r.readTable(_db.routines), r.read(count) ?? 0)
        ]);
  }

  Future<RoutineDetail?> load(int id) async {
    final routine =
        await (_db.select(_db.routines)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (routine == null) return null;
    final rows = await (_db.select(_db.routineExercises).join([
      innerJoin(_db.exercises, _db.exercises.id.equalsExp(_db.routineExercises.exerciseId)),
    ])
          ..where(_db.routineExercises.routineId.equals(id))
          ..orderBy([OrderingTerm.asc(_db.routineExercises.position)]))
        .get();
    return RoutineDetail(routine, [
      for (final r in rows)
        RoutineItem(
          r.readTable(_db.exercises),
          sets: r.readTable(_db.routineExercises).targetSets,
          reps: r.readTable(_db.routineExercises).targetReps,
        )
    ]);
  }

  /// Creates or fully replaces a routine (name + ordered items) atomically.
  Future<int> save({int? id, required String name, required List<RoutineItem> items}) =>
      _db.transaction(() async {
        final int rid;
        if (id == null) {
          rid = await _db.into(_db.routines).insert(RoutinesCompanion.insert(name: name.trim()));
        } else {
          rid = id;
          await (_db.update(_db.routines)..where((t) => t.id.equals(rid)))
              .write(RoutinesCompanion(name: Value(name.trim())));
          await (_db.delete(_db.routineExercises)..where((t) => t.routineId.equals(rid))).go();
        }
        await _db.batch((b) => b.insertAll(_db.routineExercises, [
              for (var i = 0; i < items.length; i++)
                RoutineExercisesCompanion.insert(
                  routineId: rid,
                  exerciseId: items[i].exercise.id,
                  position: i,
                  targetSets: Value(items[i].sets),
                  targetReps: Value(items[i].reps),
                )
            ]));
        return rid;
      });

  Future<void> delete(int id) =>
      (_db.delete(_db.routines)..where((t) => t.id.equals(id))).go();
}

final routineRepositoryProvider =
    Provider((ref) => RoutineRepository(ref.watch(databaseProvider)));

final routinesProvider = StreamProvider<List<RoutineSummary>>(
    (ref) => ref.watch(routineRepositoryProvider).watchAll());
