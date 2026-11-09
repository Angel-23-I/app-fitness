import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/format.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../domain/body_metrics.dart';

class MetricChart extends StatelessWidget {
  const MetricChart({super.key, required this.points, required this.metric});
  final List<(DateTime, double)> points;
  final BodyMetric metric;

  static const _day = 86400000.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (points.length < 2) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            points.isEmpty
                ? l10n.chartNeedMore
                : '${fmtNum(points.first.$2)} ${metric.unit}\n${l10n.chartNeedMore}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final spots = [for (final (d, v) in points) FlSpot(d.millisecondsSinceEpoch / _day, v)];
    final minX = spots.first.x, maxX = spots.last.x;
    final ys = spots.map((s) => s.y);
    final lo = ys.reduce((a, b) => a < b ? a : b), hi = ys.reduce((a, b) => a > b ? a : b);
    final pad = (hi - lo) < 1 ? 1.0 : (hi - lo) * 0.15;
    final fmt = DateFormat.Md('es');

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(LineChartData(
          minX: minX,
          maxX: maxX,
          minY: lo - pad,
          maxY: hi + pad,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: scheme.outlineVariant, strokeWidth: 1, dashArray: const [3, 5]),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, meta) => v == meta.min || v == meta.max
                    ? const SizedBox.shrink()
                    : Text(fmtNum(v), style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (maxX - minX) / 3,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    fmt.format(DateTime.fromMillisecondsSinceEpoch((v * _day).round())),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: scheme.primary,
              barWidth: 3,
              dotData: FlDotData(
                checkToShowDot: (spot, _) => spot == spots.last,
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                    radius: 5, color: scheme.surface, strokeWidth: 3, strokeColor: scheme.primary),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [scheme.primary.withValues(alpha: 0.35), scheme.primary.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}
