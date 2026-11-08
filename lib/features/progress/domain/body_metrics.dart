import '../../../core/db/app_database.dart';

enum BodyMetric {
  weight('kg'),
  waist('cm'),
  chest('cm'),
  arm('cm'),
  thigh('cm');

  const BodyMetric(this.unit);
  final String unit;

  double? of(BodyEntry e) => switch (this) {
        weight => e.weightKg,
        waist => e.waistCm,
        chest => e.chestCm,
        arm => e.armCm,
        thigh => e.thighCm,
      };
}

enum ChartRange {
  month(30),
  threeMonths(90),
  all(null);

  const ChartRange(this.days);
  final int? days;
}

/// (date, value) points of [metric] inside [range], oldest first; entries without the metric are skipped.
List<(DateTime, double)> metricSeries(
    List<BodyEntry> entries, BodyMetric metric, ChartRange range, DateTime now) {
  final from = range.days == null ? null : now.subtract(Duration(days: range.days!));
  final points = [
    for (final e in entries)
      if (metric.of(e) case final v? when from == null || !e.date.isBefore(from)) (e.date, v)
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  return points;
}
