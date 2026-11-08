import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/core/db/app_database.dart';
import 'package:fittrack/core/db/enums.dart';
import 'package:fittrack/features/nutrition/data/meal_repository.dart';
import 'package:fittrack/features/nutrition/domain/food_models.dart';

void main() {
  late AppDatabase db;
  late MealRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MealRepository(db);
  });
  tearDown(() => db.close());

  const rice = FoodItemDraft(name: 'Arroz', grams: 150, kcal: 195, proteinG: 4, carbsG: 42, fatG: 0.4);
  const chicken = FoodItemDraft(name: 'Pollo', grams: 120, kcal: 198, proteinG: 37, carbsG: 0, fatG: 4.3);

  test('saves meals with items and groups them by local day', () async {
    final day = DateTime(2026, 6, 10);
    await repo.save(type: MealType.lunch, eatenAt: DateTime(2026, 6, 10, 14), items: [rice, chicken]);
    await repo.save(type: MealType.dinner, eatenAt: DateTime(2026, 6, 10, 21, 30), items: [rice]);
    await repo.save(type: MealType.snack, eatenAt: DateTime(2026, 6, 11, 0, 5), items: [rice]);

    final meals = await repo.watchDay(day).first;
    expect(meals.length, 2);
    expect(meals.first.meal.mealType, MealType.lunch);
    expect(meals.first.totals.kcal, 393);
    expect(meals.fold<double>(0, (s, m) => s + m.totals.kcal), 588);
    expect((await repo.watchDay(DateTime(2026, 6, 11)).first).length, 1);
    expect(await repo.watchDay(DateTime(2026, 6, 9)).first, isEmpty);
  });

  test('deleting a meal removes its items', () async {
    final id = await repo.save(type: MealType.snack, eatenAt: DateTime(2026, 6, 10, 10), items: [rice]);
    await repo.delete(id);
    expect(await db.select(db.mealItems).get(), isEmpty);
  });
}
