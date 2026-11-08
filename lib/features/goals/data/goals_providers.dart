import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/data/settings_repository.dart';
import '../../workout/data/workout_repository.dart';
import '../domain/goals.dart';
import '../domain/streaks.dart';

final goalsProvider = StreamProvider<Goals>(
    (ref) => ref.watch(settingsRepositoryProvider).watchAll().map(Goals.fromSettings));

/// Start times of every finished workout.
final workoutDatesProvider = Provider.autoDispose<AsyncValue<List<DateTime>>>((ref) =>
    ref.watch(historyProvider).whenData((l) => [for (final s in l) s.workout.startedAt]));

class TrainingStats {
  const TrainingStats(
      {required this.dayStreak, required this.weekStreak, required this.thisWeek, required this.goal});
  final int dayStreak, weekStreak, thisWeek, goal;
}

final trainingStatsProvider = Provider.autoDispose<AsyncValue<TrainingStats>>((ref) {
  final dates = ref.watch(workoutDatesProvider);
  final goal = ref.watch(goalsProvider).value?.weeklyWorkouts ?? Goals.defaultWeeklyWorkouts;
  final now = DateTime.now();
  return dates.whenData((d) => TrainingStats(
        dayStreak: dayStreak(d, now),
        weekStreak: weekStreak(d, now, goal: goal),
        thisWeek: workoutsThisWeek(d, now),
        goal: goal,
      ));
});
