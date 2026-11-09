import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/app.dart';
import 'package:fittrack/core/db/app_database.dart';
import 'package:fittrack/core/db/enums.dart';
import 'package:fittrack/features/goals/domain/goals.dart';
import 'package:fittrack/features/goals/data/goals_providers.dart';
import 'package:fittrack/features/nutrition/data/meal_repository.dart';
import 'package:fittrack/features/progress/data/body_repository.dart';
import 'package:fittrack/features/routines/data/routine_repository.dart';
import 'package:fittrack/features/routines/domain/routine_models.dart';
import 'package:fittrack/features/workout/data/workout_repository.dart';
import 'package:fittrack/features/workout/domain/workout_models.dart';

void main() {
  testWidgets('bottom navigation switches between tabs', (tester) async {
    // Streams are faked: drift's real async work does not run inside testWidgets' fake clock.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        routinesProvider.overrideWith((ref) => Stream.value(<RoutineSummary>[])),
        historyProvider.overrideWith((ref) => Stream.value(<WorkoutSummary>[])),
        activeWorkoutProvider.overrideWith((ref) => Stream.value(null)),
        bodyEntriesProvider.overrideWith((ref) => Stream.value(<BodyEntry>[])),
        goalsProvider.overrideWith((ref) => Stream.value(const Goals())),
        todayMealsProvider.overrideWith((ref) => Stream.value(<MealWithItems>[])),
      ],
      child: const FitTrackApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ENTRENAMIENTO SUGERIDO PARA HOY'), findsOneWidget);
    expect(find.text('Entrenos'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Rutinas'));
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
    expect((await db.select(db.exercises).get()).any((e) => e.name == 'Press banca'), isTrue);
  });
}
