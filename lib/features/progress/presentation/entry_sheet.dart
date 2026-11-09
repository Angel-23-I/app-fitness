import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/body_repository.dart';

Future<void> showEntrySheet(BuildContext context, {BodyEntry? entry}) =>
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EntrySheet(entry: entry),
    );

class _EntrySheet extends ConsumerStatefulWidget {
  const _EntrySheet({this.entry});
  final BodyEntry? entry;

  @override
  ConsumerState<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<_EntrySheet> {
  late DateTime _date = widget.entry?.date ?? DateTime.now();
  late final _weight = _ctrl(widget.entry?.weightKg);
  late final _waist = _ctrl(widget.entry?.waistCm);
  late final _chest = _ctrl(widget.entry?.chestCm);
  late final _arm = _ctrl(widget.entry?.armCm);
  late final _thigh = _ctrl(widget.entry?.thighCm);
  var _error = false;

  TextEditingController _ctrl(double? v) => TextEditingController(text: v == null ? '' : fmtNum(v));

  @override
  void dispose() {
    for (final c in [_weight, _waist, _chest, _arm, _thigh]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final v = [for (final c in [_weight, _waist, _chest, _arm, _thigh]) parseNum(c.text)];
    if (v.every((e) => e == null)) {
      setState(() => _error = true);
      return;
    }
    await ref.read(bodyRepositoryProvider).save(
          id: widget.entry?.id,
          date: DateTime(_date.year, _date.month, _date.day),
          weightKg: v[0],
          waistCm: v[1],
          chestCm: v[2],
          armCm: v[3],
          thighCm: v[4],
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget field(TextEditingController c, String label, String suffix) => Expanded(
          child: TextField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: label, suffixText: suffix),
          ),
        );
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(l10n.entryDate),
            subtitle: Text(fmtDate(_date)),
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now());
              if (d != null) setState(() => _date = d);
            },
          ),
          Row(children: [field(_weight, l10n.metricWeight, 'kg')]),
          const SizedBox(height: 12),
          Row(children: [
            field(_waist, l10n.metricWaist, 'cm'),
            const SizedBox(width: 12),
            field(_chest, l10n.metricChest, 'cm'),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            field(_arm, l10n.metricArm, 'cm'),
            const SizedBox(width: 12),
            field(_thigh, l10n.metricThigh, 'cm'),
          ]),
          if (_error)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.entryNeedValue,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 16),
          SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: Text(l10n.save))),
        ]),
      ),
    );
  }
}
