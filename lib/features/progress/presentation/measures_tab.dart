import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
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
          return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), children: [
            SegmentedButton<ChartRange>(
              showSelectedIcon: false,
              segments: [
                for (final r in ChartRange.values)
                  ButtonSegment(value: r, label: Text(rangeLabels[r]!)),
              ],
              selected: {_range},
              onSelectionChanged: (s) => setState(() => _range = s.first),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final m in BodyMetric.values)
                ChoiceChip(
                  label: Text(m.label(l10n)),
                  selected: _metric == m,
                  onSelected: (_) => setState(() => _metric = m),
                ),
            ]),
            const SizedBox(height: 16),
            MetricChart(points: points, metric: _metric),
            const SizedBox(height: 16),
            for (final e in list) _EntryTile(e),
          ]);
        },
      ),
    );
  }
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
