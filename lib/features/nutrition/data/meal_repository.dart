import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/enums.dart';
import '../../../core/db/providers.dart';
import '../domain/food_models.dart';

class MealWithItems {
  const MealWithItems(this.meal, this.items);
  final Meal meal;
  final List<MealItem> items;

  Totals get totals => Totals(
        kcal: items.fold(0, (s, e) => s + e.kcal),
        proteinG: items.fold(0, (s, e) => s + e.proteinG),
        carbsG: items.fold(0, (s, e) => s + e.carbsG),
        fatG: items.fold(0, (s, e) => s + e.fatG),
      );
}

class MealRepository {
  MealRepository(this._db);
  final AppDatabase _db;

  /// Meals eaten on the local calendar day of [day], oldest first.
  Stream<List<MealWithItems>> watchDay(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);
    final q = _db.select(_db.meals).join([
      leftOuterJoin(_db.mealItems, _db.mealItems.mealId.equalsExp(_db.meals.id)),
    ])
      ..where(_db.meals.eatenAt.isBiggerOrEqualValue(from) & _db.meals.eatenAt.isSmallerThanValue(to))
      ..orderBy([OrderingTerm.asc(_db.meals.eatenAt), OrderingTerm.asc(_db.mealItems.id)]);
    return q.watch().map((rows) {
      final items = <int, List<MealItem>>{};
      final meals = <int, Meal>{};
      for (final r in rows) {
        final m = r.readTable(_db.meals);
        meals[m.id] = m;
        final i = r.readTableOrNull(_db.mealItems);
        (items[m.id] ??= []);
        if (i != null) items[m.id]!.add(i);
      }
      return [for (final m in meals.values) MealWithItems(m, items[m.id]!)];
    });
  }

  Future<int> save({
    required MealType type,
    required DateTime eatenAt,
    required List<FoodItemDraft> items,
  }) =>
      _db.transaction(() async {
        final id = await _db.into(_db.meals).insert(
            MealsCompanion.insert(eatenAt: eatenAt, mealType: Value(type)));
        await _db.batch((b) => b.insertAll(_db.mealItems, [
              for (final i in items)
                MealItemsCompanion.insert(
                    mealId: id,
                    name: i.name,
                    grams: i.grams,
                    kcal: i.kcal,
                    proteinG: i.proteinG,
                    carbsG: i.carbsG,
                    fatG: i.fatG),
            ]));
        return id;
      });

  Future<void> delete(int mealId) =>
      (_db.delete(_db.meals)..where((t) => t.id.equals(mealId))).go();
}

final mealRepositoryProvider = Provider((ref) => MealRepository(ref.watch(databaseProvider)));

/// Day shown on the meals screen (date only).
class SelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void shift(int days) => state = DateTime(state.year, state.month, state.day + days);
}

final selectedDayProvider = NotifierProvider<SelectedDay, DateTime>(SelectedDay.new);

final dayMealsProvider = StreamProvider.autoDispose<List<MealWithItems>>(
    (ref) => ref.watch(mealRepositoryProvider).watchDay(ref.watch(selectedDayProvider)));

final todayMealsProvider = StreamProvider.autoDispose<List<MealWithItems>>(
    (ref) => ref.watch(mealRepositoryProvider).watchDay(DateTime.now()));
