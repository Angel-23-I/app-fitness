class Goals {
  const Goals({this.targetWeightKg, this.weeklyWorkouts = defaultWeeklyWorkouts, this.dailyCalories});

  static const defaultWeeklyWorkouts = 3;

  final double? targetWeightKg;
  final int weeklyWorkouts;
  final int? dailyCalories;

  /// Builds goals from raw key/value settings; invalid values fall back to defaults.
  factory Goals.fromSettings(Map<String, String> s) => Goals(
        targetWeightKg: double.tryParse(s['targetWeight'] ?? ''),
        weeklyWorkouts: int.tryParse(s['weeklyWorkouts'] ?? '') ?? defaultWeeklyWorkouts,
        dailyCalories: int.tryParse(s['dailyCalories'] ?? ''),
      );
}
