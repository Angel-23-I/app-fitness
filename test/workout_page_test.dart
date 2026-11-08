import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fittrack/core/db/app_database.dart';
import 'package:fittrack/core/db/enums.dart';
import 'package:fittrack/core/theme/app_theme.dart';
import 'package:fittrack/features/settings/data/settings_repository.dart';
import 'package:fittrack/features/workout/data/workout_repository.dart';
import 'package:fittrack/features/workout/domain/workout_models.dart';
import 'package:fittrack/features/workout/presentation/workout_page.dart';
import 'package:fittrack/l10n/gen/app_localizations.dart';

class _MockRepo extends Mock implements WorkoutRepository {}

void main() {
  testWidgets('completing a set saves it and starts the rest timer', (tester) async {
    const exercise = Exercise(
        id: 5,
        name: 'Press banca',
        muscleGroup: MuscleGroup.chest,
        equipment: Equipment.barbell,
        isCustom: false);
    final workout = Workout(id: 1, routineId: 1, name: 'Push', startedAt: DateTime(2026, 1, 1));
    WorkoutSession session({required bool done}) => WorkoutSession(workout, [
          ExerciseBlock(exercise, [
            WorkoutSet(
                id: 10,
                workoutId: 1,
                exerciseId: 5,
                exerciseOrder: 0,
                setNumber: 1,
                reps: 8,
                weightKg: 60,
                completed: done),
          ])
        ]);

    final stream = StreamController<WorkoutSession?>();
    addTearDown(stream.close);
    final repo = _MockRepo();
    when(() => repo.updateSet(any(),
            reps: any(named: 'reps'),
            weightKg: any(named: 'weightKg'),
            completed: any(named: 'completed')))
        .thenAnswer((_) async => stream.add(session(done: true)));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repo),
        workoutSessionProvider(1).overrideWith((ref) => stream.stream),
        lastPerformanceProvider(5).overrideWith((ref) async => <WorkoutSet>[]),
        restSecondsProvider.overrideWith((ref) => Stream.value(90)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WorkoutPage(workoutId: 1),
      ),
    ));
    stream.add(session(done: false));
    await tester.pump();
    await tester.pump();

    expect(find.text('Press banca'), findsOneWidget);
    expect(find.text('Descanso 01:30'), findsNothing);

    await tester.tap(find.byTooltip('Serie completada'));
    await tester.pump();
    await tester.pump();

    verify(() => repo.updateSet(10, weightKg: 60, reps: 8, completed: true)).called(1);
    expect(find.textContaining('Descanso 01:'), findsOneWidget);

    // Unmount so the rest timer's periodic Timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });
}
