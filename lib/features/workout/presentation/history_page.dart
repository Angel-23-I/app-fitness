import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/workout_repository.dart';
import '../domain/workout_models.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: l10n.recordsTitle,
            onPressed: () => context.push('/records'),
          ),
        ],
      ),
      body: AsyncBody<List<WorkoutSummary>>(
        value: ref.watch(historyProvider),
        onRetry: () => ref.invalidate(historyProvider),
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(icon: Icons.history, message: l10n.historyEmpty),
        builder: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final s = list[i];
            return Dismissible(
              key: ValueKey(s.workout.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              ),
              confirmDismiss: (_) => _confirmDelete(context, s.workout.name),
              onDismissed: (_) async {
                await ref.read(workoutRepositoryProvider).deleteWorkout(s.workout.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Entrenamiento "${s.workout.name}" eliminado')),
                  );
                }
              },
              child: Card(
                child: ListTile(
                  title: Text(s.workout.name),
                  subtitle: Text('${fmtDateTime(s.workout.startedAt)}\n'
                      '${l10n.durationMin(s.duration.inMinutes)} · ${l10n.workoutSummary(s.sets, fmtNum(s.volumeKg))}'),
                  isThreeLine: true,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.muted),
                      tooltip: 'Eliminar',
                      onPressed: () async {
                        if (await _confirmDelete(context, s.workout.name)) {
                          await ref.read(workoutRepositoryProvider).deleteWorkout(s.workout.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Entrenamiento "${s.workout.name}" eliminado')),
                            );
                          }
                        }
                      },
                    ),
                    const Icon(Icons.chevron_right),
                  ]),
                  onTap: () => context.push('/history/${s.workout.id}'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Eliminar entrenamiento?'),
            content: Text('Se borrará la sesión "$name" y sus series del historial de forma permanente.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
