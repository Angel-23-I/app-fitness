import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/routine_repository.dart';
import '../domain/routine_models.dart';

class RoutinesPage extends ConsumerWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navRoutines),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: l10n.exercisesTitle,
            onPressed: () => context.push('/exercises'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.historyTitle,
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/routines/edit'),
        icon: const Icon(Icons.add),
        label: Text(l10n.routineNew),
      ),
      body: AsyncBody<List<RoutineSummary>>(
        value: ref.watch(routinesProvider),
        onRetry: () => ref.invalidate(routinesProvider),
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(icon: Icons.fitness_center, message: l10n.routinesEmpty),
        builder: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _RoutineCard(list[i]),
        ),
      ),
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard(this.s);
  final RoutineSummary s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        title: Text(s.routine.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(l10n.routineExerciseCount(s.exerciseCount)),
        onTap: () => context.push('/routines/edit?id=${s.routine.id}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (s.exerciseCount > 0)
            FilledButton.icon(
              onPressed: () => context.push('/workout/${s.routine.id}'),
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.workoutStart),
            ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                context.push('/routines/edit?id=${s.routine.id}');
              } else if (await _confirmDelete(context)) {
                await ref.read(routineRepositoryProvider).delete(s.routine.id);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ]),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.routineDeleteTitle),
            content: Text(l10n.routineDeleteBody),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
            ],
          ),
        ) ??
        false;
  }
}
