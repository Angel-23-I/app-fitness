import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../settings/data/settings_repository.dart';
import '../data/workout_repository.dart';
import '../domain/workout_models.dart';
import 'rest_timer.dart';

class WorkoutPage extends ConsumerWidget {
  const WorkoutPage({super.key, required this.workoutId});
  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(workoutSessionProvider(workoutId));
    final session = async.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(session?.workout.name ?? l10n.workoutTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              if (v == 'discard' && await _confirm(context, l10n.workoutDiscardTitle, l10n.workoutDiscardBody)) {
                await ref.read(workoutRepositoryProvider).discard(workoutId);
                if (context.mounted) context.pop();
              } else if (v.startsWith('rest')) {
                await ref
                    .read(settingsRepositoryProvider)
                    .set(SettingKeys.restSeconds, v.substring(4));
              }
            },
            itemBuilder: (_) => [
              for (final s in const [30, 60, 90, 120, 180])
                PopupMenuItem(value: 'rest$s', child: Text(l10n.restDuration(s))),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'discard', child: Text(l10n.workoutDiscard)),
            ],
          ),
          TextButton(
            onPressed: session == null ? null : () => _finish(context, ref, session),
            child: Text(l10n.workoutFinish),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: AsyncBody<WorkoutSession?>(
            value: async,
            onRetry: () => ref.invalidate(workoutSessionProvider(workoutId)),
            builder: (s) => s == null
                ? EmptyState(icon: Icons.search_off, message: l10n.workoutNotFound)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: s.blocks.length,
                    itemBuilder: (_, i) =>
                        _BlockCard(workoutId: workoutId, order: i, block: s.blocks[i]),
                  ),
          ),
        ),
        const RestTimerBar(),
      ]),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref, WorkoutSession s) async {
    final l10n = AppLocalizations.of(context);
    if (!s.hasCompletedSet) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.workoutNothingDone)));
      return;
    }
    if (!await _confirm(context, l10n.workoutFinishTitle, l10n.workoutFinishBody)) return;
    final broken = await ref.read(workoutRepositoryProvider).finish(workoutId);
    ref.read(restTimerProvider.notifier).stop();
    if (!context.mounted) return;
    if (broken.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.emoji_events, size: 40),
          title: Text(l10n.newRecordsTitle),
          content: Text(l10n.newRecordsBody(broken.map((e) => e.name).join(', '))),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok))],
        ),
      );
    }
    if (context.mounted) context.pushReplacement('/history/$workoutId');
  }
}

Future<bool> _confirm(BuildContext context, String title, String body) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.ok)),
          ],
        ),
      ) ??
      false;
}

class _BlockCard extends ConsumerWidget {
  const _BlockCard({required this.workoutId, required this.order, required this.block});
  final int workoutId;
  final int order;
  final ExerciseBlock block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final last = ref.watch(lastPerformanceProvider(block.exercise.id)).value;
    final lastText = last == null
        ? ''
        : last.isEmpty
            ? l10n.lastTimeNone
            : l10n.lastTime(last.map((s) => '${fmtNum(s.weightKg)}×${s.reps}').join('  '));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(block.exercise.name, style: Theme.of(context).textTheme.titleMedium),
            if (lastText.isNotEmpty)
              Text(lastText, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            for (var i = 0; i < block.sets.length; i++)
              _SetRow(key: ValueKey(block.sets[i].id), index: i + 1, set: block.sets[i]),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => ref.read(workoutRepositoryProvider).addSet(workoutId, order),
                icon: const Icon(Icons.add),
                label: Text(l10n.addSet),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  const _SetRow({super.key, required this.index, required this.set});
  final int index;
  final WorkoutSet set;

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late final _weight = TextEditingController(text: fmtNum(widget.set.weightKg));
  late final _reps = TextEditingController(text: '${widget.set.reps}');

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  Future<void> _save({bool? completed}) =>
      ref.read(workoutRepositoryProvider).updateSet(
            widget.set.id,
            weightKg: parseNum(_weight.text) ?? 0,
            reps: int.tryParse(_reps.text.trim()) ?? 0,
            completed: completed,
          );

  Future<void> _toggle() async {
    final done = !widget.set.completed;
    await _save(completed: done);
    if (done) {
      final secs = ref.read(restSecondsProvider).value ?? defaultRestSeconds;
      ref.read(restTimerProvider.notifier).start(secs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = widget.set.completed;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: done ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        SizedBox(width: 28, child: Text('${widget.index}', style: Theme.of(context).textTheme.titleSmall)),
        Expanded(
          child: TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(labelText: l10n.setWeight, isDense: true),
            onChanged: (_) => _save(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _reps,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(labelText: l10n.reps, isDense: true),
            onChanged: (_) => _save(),
          ),
        ),
        IconButton.filled(
          tooltip: l10n.setDone,
          isSelected: done,
          icon: const Icon(Icons.check),
          selectedIcon: const Icon(Icons.check),
          style: done ? null : IconButton.styleFrom(backgroundColor: scheme.surfaceContainerHighest, foregroundColor: scheme.onSurfaceVariant),
          onPressed: _toggle,
        ),
        IconButton(
          tooltip: l10n.delete,
          icon: const Icon(Icons.close, size: 18),
          onPressed: () => ref.read(workoutRepositoryProvider).removeSet(widget.set.id),
        ),
      ]),
    );
  }
}
