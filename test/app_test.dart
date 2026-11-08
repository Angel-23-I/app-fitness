import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/app.dart';
import 'package:fittrack/core/db/app_database.dart';
import 'package:fittrack/core/db/enums.dart';
import 'package:fittrack/core/db/providers.dart';

void main() {
  testWidgets('bottom navigation switches between tabs', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const FitTrackApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tu resumen del día aparecerá aquí.'), findsOneWidget);
    await tester.tap(find.text('Rutinas'));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu primera rutina para empezar a entrenar.'), findsOneWidget);
  });

  test('database inserts and cascades deletes', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ex = await db.into(db.exercises).insert(ExercisesCompanion.insert(
        name: 'Press banca', muscleGroup: MuscleGroup.chest, equipment: Equipment.barbell));
    final r = await db.into(db.routines).insert(RoutinesCompanion.insert(name: 'Push'));
    await db.into(db.routineExercises).insert(RoutineExercisesCompanion.insert(
        routineId: r, exerciseId: ex, position: 0));

    await (db.delete(db.routines)..where((t) => t.id.equals(r))).go();
    expect(await db.select(db.routineExercises).get(), isEmpty);
    expect((await db.select(db.exercises).get()).single.name, 'Press banca');
  });
}
