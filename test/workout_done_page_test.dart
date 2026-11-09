import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/core/theme/app_theme.dart';
import 'package:fittrack/features/goals/data/goals_providers.dart';
import 'package:fittrack/features/workout/domain/workout_models.dart';
import 'package:fittrack/features/workout/presentation/workout_done_page.dart';
import 'package:fittrack/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('finish screen shows totals, streak and records on a phone', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        trainingStatsProvider.overrideWithValue(
            const AsyncValue.data(TrainingStats(dayStreak: 4, weekStreak: 2, thisWeek: 2, goal: 3))),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WorkoutDonePage(
          result: WorkoutResult(
            workoutId: 1,
            name: 'Pechito',
            duration: Duration(minutes: 47, seconds: 5),
            sets: 12,
            exercises: 4,
            volumeKg: 5340,
            records: ['Press de banca', 'Aperturas con mancuernas'],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('¡ENTRENAMIENTO COMPLETADO!'), findsOneWidget);
    expect(find.textContaining('47:05', findRichText: true), findsOneWidget);
    expect(find.textContaining(RegExp(r'5.?340'), findRichText: true), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('• Aperturas con mancuernas'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('¡NUEVO RÉCORD!'), findsOneWidget);
    expect(find.text('• Press de banca'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
