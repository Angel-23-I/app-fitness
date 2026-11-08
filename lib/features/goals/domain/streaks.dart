DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monday 00:00 of the week containing [d].
DateTime startOfWeek(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// Consecutive days with at least one workout, ending today. A missing today does not
/// break the streak yet (the day is still in progress), so it may end yesterday.
int dayStreak(Iterable<DateTime> workoutDates, DateTime now) {
  final days = workoutDates.map(startOfDay).toSet();
  var d = startOfDay(now);
  if (!days.contains(d)) d = DateTime(d.year, d.month, d.day - 1);
  var n = 0;
  while (days.contains(d)) {
    n++;
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return n;
}

int workoutsThisWeek(Iterable<DateTime> workoutDates, DateTime now) {
  final start = startOfWeek(now);
  return workoutDates.where((d) => !d.isBefore(start)).length;
}

/// Consecutive weeks (Mon-Sun) with at least [goal] workouts. The current week counts
/// only once met; while in progress it does not break the streak.
int weekStreak(Iterable<DateTime> workoutDates, DateTime now, {required int goal}) {
  final need = goal < 1 ? 1 : goal;
  final perWeek = <DateTime, int>{};
  for (final d in workoutDates) {
    perWeek.update(startOfWeek(d), (v) => v + 1, ifAbsent: () => 1);
  }
  var week = startOfWeek(now);
  var n = 0;
  if ((perWeek[week] ?? 0) >= need) n++;
  week = DateTime(week.year, week.month, week.day - 7);
  while ((perWeek[week] ?? 0) >= need) {
    n++;
    week = DateTime(week.year, week.month, week.day - 7);
  }
  return n;
}
