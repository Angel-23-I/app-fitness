import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/reminder_repository.dart';

/// 2024-01-01 was a Monday, so weekday n maps to day n of that week.
DateTime _dayOf(int weekday) => DateTime(2024, 1, weekday);

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add_alert_outlined),
        label: Text(l10n.reminderAdd),
      ),
      body: AsyncBody<List<Reminder>>(
        value: ref.watch(remindersProvider),
        onRetry: () => ref.invalidate(remindersProvider),
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(icon: Icons.notifications_none, message: l10n.remindersEmpty),
        builder: (list) => ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final r = list[i];
            final time = TimeOfDay(hour: r.hour, minute: r.minute).format(context);
            return SwitchListTile(
              value: r.enabled,
              title: Text('${toBeginningOfSentenceCase(DateFormat.EEEE('es').format(_dayOf(r.weekday)))} · $time'),
              secondary: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.delete,
                onPressed: () => ref.read(reminderRepositoryProvider).delete(r),
              ),
              onChanged: (v) => ref.read(reminderRepositoryProvider).setEnabled(r, v),
            );
          },
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final days = <int>{};
    final time = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
    if (time == null || !context.mounted) return;
    final chosen = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l10n.reminderDays),
          content: Wrap(spacing: 8, children: [
            for (var d = DateTime.monday; d <= DateTime.sunday; d++)
              FilterChip(
                label: Text(toBeginningOfSentenceCase(DateFormat.E('es').format(_dayOf(d)))),
                selected: days.contains(d),
                onSelected: (v) => setS(() => v ? days.add(d) : days.remove(d)),
              ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.save)),
          ],
        ),
      ),
    );
    if (chosen != true || days.isEmpty) return;
    final ok = await ref.read(reminderRepositoryProvider).add(days, time.hour, time.minute);
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(l10n.reminderPermissionDenied)));
  }
}
