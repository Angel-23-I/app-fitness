import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/core/db/app_database.dart';
import 'package:fittrack/features/progress/data/body_repository.dart';
import 'package:fittrack/features/progress/domain/body_metrics.dart';

BodyEntry _e(int id, DateTime d, {double? w, double? waist}) => BodyEntry(
    id: id, date: d, weightKg: w, waistCm: waist, chestCm: null, armCm: null, thighCm: null);

void main() {
  final now = DateTime(2026, 6, 30);
  final entries = [
    _e(1, DateTime(2026, 6, 25), w: 80, waist: 90),
    _e(2, DateTime(2026, 3, 1), w: 84),
    _e(3, DateTime(2026, 6, 10), w: 81),
    _e(4, DateTime(2026, 6, 20), waist: 91),
  ];

  test('metricSeries filters by range, skips missing values and sorts by date', () {
    expect(metricSeries(entries, BodyMetric.weight, ChartRange.month, now).map((p) => p.$2),
        [81, 80]);
    expect(metricSeries(entries, BodyMetric.weight, ChartRange.threeMonths, now).length, 2);
    expect(metricSeries(entries, BodyMetric.weight, ChartRange.all, now).map((p) => p.$2),
        [84, 81, 80]);
    expect(metricSeries(entries, BodyMetric.waist, ChartRange.all, now).map((p) => p.$2), [91, 90]);
  });

  test('repository saves, updates and deletes entries', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = BodyRepository(db);

    await repo.save(date: DateTime(2026, 1, 1), weightKg: 80, waistCm: 90);
    var list = await repo.watchEntries().first;
    await repo.save(id: list.single.id, date: DateTime(2026, 1, 1), weightKg: 79.5);
    list = await repo.watchEntries().first;
    expect(list.single.weightKg, 79.5);
    expect(list.single.waistCm, isNull);

    await repo.delete(list.single.id);
    expect(await repo.watchEntries().first, isEmpty);
  });
}
