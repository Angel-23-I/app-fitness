import 'package:drift/drift.dart';

import 'enums.dart';

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get muscleGroup => textEnum<MuscleGroup>()();
  TextColumn get equipment => textEnum<Equipment>()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
}

class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class RoutineExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId =>
      integer().references(Routines, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.restrict)();
  IntColumn get position => integer()();
  IntColumn get targetSets => integer().withDefault(const Constant(3))();
  IntColumn get targetReps => integer().withDefault(const Constant(10))();
}

class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Nullable and set-null so history survives deleting the routine.
  IntColumn get routineId =>
      integer().nullable().references(Routines, #id, onDelete: KeyAction.setNull)();
  TextColumn get name => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
}

class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.restrict)();
  IntColumn get exerciseOrder => integer()();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  RealColumn get weightKg => real().withDefault(const Constant(0))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

class BodyEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get chestCm => real().nullable()();
  RealColumn get armCm => real().nullable()();
  RealColumn get thighCm => real().nullable()();
}

class ProgressPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get path => text()();
}

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get weekday => integer()(); // DateTime.monday .. DateTime.sunday
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}

/// Key/value store for goals and preferences (non-secret). The API key lives in secure storage.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get eatenAt => dateTime()();
  TextColumn get mealType => textEnum<MealType>().withDefault(const Constant('snack'))();
  TextColumn get photoPath => text().nullable()();
}

class MealItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mealId =>
      integer().references(Meals, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  RealColumn get grams => real()();
  RealColumn get kcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();
}
