import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fit_widgets.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/body_repository.dart';
import '../domain/body_metrics.dart';
import 'entry_sheet.dart';
import 'metric_chart.dart';

extension BodyMetricLabel on BodyMetric {
  String label(AppLocalizations l) => switch (this) {
        BodyMetric.weight => l.metricWeight,
        BodyMetric.waist => l.metricWaist,
        BodyMetric.chest => l.metricChest,
        BodyMetric.arm => l.metricArm,
        BodyMetric.thigh => l.metricThigh,
      };
}

class MeasuresTab extends ConsumerStatefulWidget {
  const MeasuresTab({super.key});

  @override
  ConsumerState<MeasuresTab> createState() => _MeasuresTabState();
}

class _MeasuresTabState extends ConsumerState<MeasuresTab> {
  var _metric = BodyMetric.weight;
  var _range = ChartRange.threeMonths;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rangeLabels = {
      ChartRange.month: l10n.range1m,
      ChartRange.threeMonths: l10n.range3m,
      ChartRange.all: l10n.rangeAll,
    };
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showEntrySheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.entryAdd),
      ),
      body: AsyncBody<List<BodyEntry>>(
        value: ref.watch(bodyEntriesProvider),
        onRetry: () => ref.invalidate(bodyEntriesProvider),
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(icon: Icons.monitor_weight_outlined, message: l10n.measuresEmpty),
        builder: (entries) {
          final points = metricSeries(entries, _metric, _range, DateTime.now());
          final list = entries.reversed.toList();
          final latest = [for (final e in entries) ?_metric.of(e)];
          final change = points.length < 2 ? null : points.last.$2 - points.first.$2;
          return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 96), children: [
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_metric.label(l10n), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      BigValue(latest.isEmpty ? '—' : fmtNum(latest.last), unit: _metric.unit, size: 52),
                      if (change != null && change != 0)
                        Text('${change < 0 ? '↓' : '↑'} ${fmtNum(change.abs())} ${_metric.unit} · ${rangeLabels[_range]}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: change < 0 ? AppColors.lime : AppColors.accent)),
                    ]),
                  ),
                  for (final r in ChartRange.values)
                    _RangePill(
                      label: rangeLabels[r]!,
                      selected: _range == r,
                      onTap: () => setState(() => _range = r),
                    ),
                ]),
                const SizedBox(height: 8),
                MetricChart(points: points, metric: _metric),
              ]),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final m in BodyMetric.values)
                ChoiceChip(
                  label: Text(m.label(l10n)),
                  selected: _metric == m,
                  onSelected: (_) => setState(() => _metric = m),
                ),
            ]),
            const SizedBox(height: 16),
            for (final e in list) _EntryTile(e),
          ]);
        },
      ),
    );
  }
}

class _RangePill extends StatelessWidget {
  const _RangePill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: selected ? AppColors.text : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.bg : AppColors.muted)),
          ),
        ),
      );
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile(this.e);
  final BodyEntry e;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final parts = [
      for (final m in BodyMetric.values)
        if (m.of(e) case final v?) '${m.label(l10n)} ${fmtNum(v)} ${m.unit}'
    ];
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => ref.read(bodyRepositoryProvider).delete(e.id),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(fmtDate(e.date)),
        subtitle: Text(parts.join(' · ')),
        onTap: () => showEntrySheet(context, entry: e),
      ),
    );
  }
}
