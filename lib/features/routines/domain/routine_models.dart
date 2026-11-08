import '../../../core/db/app_database.dart';

class RoutineSummary {
  const RoutineSummary(this.routine, this.exerciseCount);
  final Routine routine;
  final int exerciseCount;
}

class RoutineItem {
  const RoutineItem(this.exercise, {this.sets = 3, this.reps = 10});
  final Exercise exercise;
  final int sets;
  final int reps;

  RoutineItem copyWith({int? sets, int? reps}) =>
      RoutineItem(exercise, sets: sets ?? this.sets, reps: reps ?? this.reps);
}

class RoutineDetail {
  const RoutineDetail(this.routine, this.items);
  final Routine routine;
  final List<RoutineItem> items;
}
