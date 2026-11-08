import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../routines/data/routine_repository.dart';
import '../domain/pr_calculator.dart';
import '../domain/workout_models.dart';

class WorkoutRepository {
  WorkoutRepository(this._db, this._routines);
  final AppDatabase _db;
  final RoutineRepository _routines;

  $WorkoutSetsTable get _sets => _db.workoutSets;
  $WorkoutsTable get _workouts => _db.workouts;

  /// Completed sets of finished workouts, with their exercise and workout.
  JoinedSelectStatement _finishedSets() => _db.select(_sets).join([
        innerJoin(_workouts, _workouts.id.equalsExp(_sets.workoutId)),
        innerJoin(_db.exercises, _db.exercises.id.equalsExp(_sets.exerciseId)),
      ])
        ..where(_sets.completed.equals(true) & _workouts.endedAt.isNotNull());

  Stream<Workout?> watchActive() => (_db.select(_workouts)
        ..where((t) => t.endedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
        ..limit(1))
      .watchSingleOrNull();

  /// Resumes an unfinished workout of the routine if there is one, else creates it
  /// with every set pre-filled from the last performance.
  Future<int> startWorkout(int routineId) async {
    final open = await (_db.select(_workouts)
          ..where((t) => t.routineId.equals(routineId) & t.endedAt.isNull())
          ..limit(1))
        .get();
    if (open.isNotEmpty) return open.first.id;

    final detail = await _routines.load(routineId);
    if (detail == null) throw StateError('Routine $routineId not found');
    return _db.transaction(() async {
      final wid = await _db.into(_workouts).insert(WorkoutsCompanion.insert(
          routineId: Value(routineId), name: detail.routine.name, startedAt: DateTime.now()));
      for (var i = 0; i < detail.items.length; i++) {
        final item = detail.items[i];
        final last = await lastPerformance(item.exercise.id);
        for (var s = 0; s < item.sets; s++) {
          final ref = s < last.length ? last[s] : (last.isEmpty ? null : last.last);
          await _db.into(_sets).insert(WorkoutSetsCompanion.insert(
                workoutId: wid,
                exerciseId: item.exercise.id,
                exerciseOrder: i,
                setNumber: s + 1,
                reps: Value(ref?.reps ?? item.reps),
                weightKg: Value(ref?.weightKg ?? 0),
              ));
        }
      }
      return wid;
    });
  }

  Stream<WorkoutSession?> watchSession(int id) {
    final q = _db.select(_sets).join([
      innerJoin(_db.exercises, _db.exercises.id.equalsExp(_sets.exerciseId)),
    ])
      ..where(_sets.workoutId.equals(id))
      ..orderBy([OrderingTerm.asc(_sets.exerciseOrder), OrderingTerm.asc(_sets.setNumber)]);
    return q.watch().asyncMap((rows) async {
      final workout =
          await (_db.select(_workouts)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (workout == null) return null;
      final blocks = <int, ExerciseBlock>{};
      final order = <int>[];
      for (final r in rows) {
        final set = r.readTable(_sets);
        final ex = r.readTable(_db.exercises);
        if (!blocks.containsKey(set.exerciseOrder)) {
          order.add(set.exerciseOrder);
          blocks[set.exerciseOrder] = ExerciseBlock(ex, []);
        }
        blocks[set.exerciseOrder]!.sets.add(set);
      }
      return WorkoutSession(workout, [for (final o in order) blocks[o]!]);
    });
  }

  Future<void> updateSet(int id, {int? reps, double? weightKg, bool? completed}) =>
      (_db.update(_sets)..where((t) => t.id.equals(id))).write(WorkoutSetsCompanion(
        reps: Value.absentIfNull(reps),
        weightKg: Value.absentIfNull(weightKg),
        completed: Value.absentIfNull(completed),
      ));

  /// Appends a set to an exercise block, copying the previous set's values.
  Future<void> addSet(int workoutId, int exerciseOrder) async {
    final existing = await (_db.select(_sets)
          ..where((t) => t.workoutId.equals(workoutId) & t.exerciseOrder.equals(exerciseOrder))
          ..orderBy([(t) => OrderingTerm.desc(t.setNumber)]))
        .get();
    if (existing.isEmpty) return;
    final last = existing.first;
    await _db.into(_sets).insert(WorkoutSetsCompanion.insert(
          workoutId: workoutId,
          exerciseId: last.exerciseId,
          exerciseOrder: exerciseOrder,
          setNumber: last.setNumber + 1,
          reps: Value(last.reps),
          weightKg: Value(last.weightKg),
        ));
  }

  Future<void> removeSet(int id) => (_db.delete(_sets)..where((t) => t.id.equals(id))).go();

  Future<void> discard(int id) =>
      (_db.delete(_workouts)..where((t) => t.id.equals(id))).go();

  /// Closes the workout keeping only completed sets. Returns the exercises whose
  /// personal record was broken (a first-ever performance does not count).
  Future<List<Exercise>> finish(int id) => _db.transaction(() async {
        await (_db.delete(_sets)..where((t) => t.workoutId.equals(id) & t.completed.equals(false)))
            .go();
        final rows = await (_db.select(_sets).join([
          innerJoin(_db.exercises, _db.exercises.id.equalsExp(_sets.exerciseId)),
        ])
              ..where(_sets.workoutId.equals(id)))
            .get();
        if (rows.isEmpty) {
          await discard(id);
          return <Exercise>[];
        }
        final byExercise = <int, List<PerformedSet>>{};
        final exercises = <int, Exercise>{};
        for (final r in rows) {
          final s = r.readTable(_sets);
          final e = r.readTable(_db.exercises);
          exercises[e.id] = e;
          (byExercise[e.id] ??= []).add(PerformedSet(s.weightKg, s.reps));
        }
        final broken = <Exercise>[];
        final records = await personalRecords();
        for (final entry in byExercise.entries) {
          final current = calculatePR(entry.value);
          final previous = records[entry.key];
          if (current != null && beatsRecord(previous, current)) broken.add(exercises[entry.key]!);
        }
        await (_db.update(_workouts)..where((t) => t.id.equals(id)))
            .write(WorkoutsCompanion(endedAt: Value(DateTime.now())));
        return broken;
      });

  /// Sets of the most recent finished workout that included the exercise.
  Future<List<WorkoutSet>> lastPerformance(int exerciseId) async {
    final q = _db.select(_sets).join([
      innerJoin(_workouts, _workouts.id.equalsExp(_sets.workoutId)),
    ])
      ..where(_sets.exerciseId.equals(exerciseId) &
          _sets.completed.equals(true) &
          _workouts.endedAt.isNotNull())
      ..orderBy([OrderingTerm.desc(_workouts.startedAt), OrderingTerm.asc(_sets.setNumber)]);
    final rows = await q.get();
    if (rows.isEmpty) return [];
    final lastId = rows.first.readTable(_workouts).id;
    return [
      for (final r in rows)
        if (r.readTable(_workouts).id == lastId) r.readTable(_sets)
    ];
  }

  /// Personal record per exercise id, from finished workouts.
  Future<Map<int, PersonalRecord>> personalRecords() async =>
      _groupRecords(await _finishedSets().get()).map((k, v) => MapEntry(k, v.$2));

  Stream<List<(Exercise, PersonalRecord)>> watchRecords() => _finishedSets().watch().map((rows) {
        final list = _groupRecords(rows).values.toList()
          ..sort((a, b) => a.$1.name.compareTo(b.$1.name));
        return list;
      });

  Map<int, (Exercise, PersonalRecord)> _groupRecords(List<TypedResult> rows) {
    final sets = <int, List<PerformedSet>>{};
    final ex = <int, Exercise>{};
    for (final r in rows) {
      final e = r.readTable(_db.exercises);
      final s = r.readTable(_sets);
      ex[e.id] = e;
      (sets[e.id] ??= []).add(PerformedSet(s.weightKg, s.reps));
    }
    return {
      for (final id in sets.keys)
        if (calculatePR(sets[id]!) case final pr?) id: (ex[id]!, pr)
    };
  }

  Stream<List<WorkoutSummary>> watchHistory() {
    final q = _db.select(_workouts).join([
      leftOuterJoin(_sets, _sets.workoutId.equalsExp(_workouts.id) & _sets.completed.equals(true)),
    ])
      ..where(_workouts.endedAt.isNotNull())
      ..orderBy([OrderingTerm.desc(_workouts.startedAt)]);
    return q.watch().map((rows) {
      final map = <int, WorkoutSummary>{};
      for (final r in rows) {
        final w = r.readTable(_workouts);
        final s = r.readTableOrNull(_sets);
        final prev = map[w.id];
        map[w.id] = WorkoutSummary(
          w,
          sets: (prev?.sets ?? 0) + (s == null ? 0 : 1),
          volumeKg: (prev?.volumeKg ?? 0) + (s == null ? 0 : s.weightKg * s.reps),
        );
      }
      return map.values.toList();
    });
  }
}

final workoutRepositoryProvider = Provider((ref) =>
    WorkoutRepository(ref.watch(databaseProvider), ref.watch(routineRepositoryProvider)));

final activeWorkoutProvider =
    StreamProvider<Workout?>((ref) => ref.watch(workoutRepositoryProvider).watchActive());

final workoutSessionProvider = StreamProvider.autoDispose.family<WorkoutSession?, int>(
    (ref, id) => ref.watch(workoutRepositoryProvider).watchSession(id));

final lastPerformanceProvider = FutureProvider.autoDispose.family<List<WorkoutSet>, int>(
    (ref, exerciseId) => ref.watch(workoutRepositoryProvider).lastPerformance(exerciseId));

final historyProvider = StreamProvider.autoDispose<List<WorkoutSummary>>(
    (ref) => ref.watch(workoutRepositoryProvider).watchHistory());

final recordsProvider = StreamProvider.autoDispose<List<(Exercise, PersonalRecord)>>(
    (ref) => ref.watch(workoutRepositoryProvider).watchRecords());
