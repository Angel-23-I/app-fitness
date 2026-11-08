import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/enums.dart';
import '../../../core/db/providers.dart';

class ExerciseRepository {
  ExerciseRepository(this._db);
  final AppDatabase _db;

  Stream<List<Exercise>> watchAll() =>
      (_db.select(_db.exercises)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<int> add(String name, MuscleGroup muscle, Equipment equipment) =>
      _db.into(_db.exercises).insert(ExercisesCompanion.insert(
          name: name.trim(), muscleGroup: muscle, equipment: equipment, isCustom: const Value(true)));

  /// Only custom exercises can be deleted; returns false if it is still referenced.
  Future<bool> delete(Exercise e) async {
    if (!e.isCustom) return false;
    try {
      await (_db.delete(_db.exercises)..where((t) => t.id.equals(e.id))).go();
      return true;
    } on Exception {
      return false;
    }
  }
}

final exerciseRepositoryProvider =
    Provider((ref) => ExerciseRepository(ref.watch(databaseProvider)));

final exercisesProvider =
    StreamProvider<List<Exercise>>((ref) => ref.watch(exerciseRepositoryProvider).watchAll());
