import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/features/goals/domain/goals.dart';
import 'package:fittrack/features/goals/domain/streaks.dart';

void main() {
  // Wednesday 2026-06-10 (week starts Monday 2026-06-08).
  final now = DateTime(2026, 6, 10, 12);

  group('dayStreak', () {
    test('counts consecutive days ending today', () {
      expect(dayStreak([DateTime(2026, 6, 10, 7), DateTime(2026, 6, 9), DateTime(2026, 6, 8)], now), 3);
    });
    test('today without workout does not break a streak ending yesterday', () {
      expect(dayStreak([DateTime(2026, 6, 9), DateTime(2026, 6, 8)], now), 2);
    });
    test('a gap or older last workout gives zero', () {
      expect(dayStreak([DateTime(2026, 6, 7)], now), 0);
      expect(dayStreak([], now), 0);
    });
    test('multiple workouts on one day count once', () {
      expect(dayStreak([DateTime(2026, 6, 10, 8), DateTime(2026, 6, 10, 19)], now), 1);
    });
  });

  group('weekStreak', () {
    // Weeks: 06-08 (current), 06-01, 05-25, 05-18.
    final lastWeekTwice = [DateTime(2026, 6, 2), DateTime(2026, 6, 4)];
    final weekBefore = [DateTime(2026, 5, 26), DateTime(2026, 5, 28)];

    test('current week in progress does not break the streak', () {
      expect(weekStreak([...lastWeekTwice, ...weekBefore], now, goal: 2), 2);
    });
    test('current week counts once the goal is met', () {
      final cur = [DateTime(2026, 6, 8), DateTime(2026, 6, 9)];
      expect(weekStreak([...cur, ...lastWeekTwice], now, goal: 2), 2);
    });
    test('a missed week ends the streak', () {
      expect(weekStreak([...lastWeekTwice, DateTime(2026, 5, 19)], now, goal: 2), 1);
    });
    test('goal below 1 is treated as 1', () {
      expect(weekStreak([DateTime(2026, 6, 2)], now, goal: 0), 1);
    });
  });

  test('workoutsThisWeek only counts since Monday', () {
    expect(
        workoutsThisWeek([DateTime(2026, 6, 7, 23), DateTime(2026, 6, 8), DateTime(2026, 6, 10)], now), 2);
  });

  test('Goals.fromSettings tolerates missing and invalid values', () {
    final g = Goals.fromSettings({'weeklyWorkouts': 'x', 'targetWeight': '72.5'});
    expect(g.weeklyWorkouts, 3);
    expect(g.targetWeightKg, 72.5);
    expect(g.dailyCalories, isNull);
  });
}
