import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fit_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../settings/data/settings_repository.dart';
import '../data/workout_repository.dart';
import '../domain/workout_models.dart';

class HistoryDetailPage extends ConsumerWidget {
  const HistoryDetailPage({super.key, required this.workoutId});
  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(workoutSessionProvider(workoutId));
    final noteAsync = ref.watch(settingsRepositoryProvider).watch('${SettingKeys.workoutNotePrefix}$workoutId');

    return Scaffold(
      appBar: AppBar(
        title: Text(async.value?.workout.name ?? l10n.historyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Eliminar entrenamiento',
            onPressed: () async {
              final ok = await _confirmDelete(context, async.value?.workout.name ?? 'este entrenamiento');
              if (ok == true) {
                await ref.read(workoutRepositoryProvider).deleteWorkout(workoutId);
                await ref.read(settingsRepositoryProvider).set('${SettingKeys.workoutNotePrefix}$workoutId', null);
                if (context.mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entrenamiento eliminado')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: AsyncBody<WorkoutSession?>(
        value: async,
        onRetry: () => ref.invalidate(workoutSessionProvider(workoutId)),
        builder: (s) => s == null
            ? EmptyState(icon: Icons.search_off, message: l10n.workoutNotFound)
            : StreamBuilder<String?>(
                stream: noteAsync,
                builder: (context, noteSnapshot) {
                  final note = noteSnapshot.data;
                  return ListView(padding: const EdgeInsets.all(16), children: [
                    Text(fmtDateTime(s.workout.startedAt), style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (note != null && note.isNotEmpty) ...[
                      Panel(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        color: AppColors.surfaceHigh,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.edit_note_rounded, color: AppColors.accent, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              note,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSoft),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],
                    for (final b in s.blocks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(b.exercise.name, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              for (var i = 0; i < b.sets.length; i++)
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _editSet(context, ref, b.sets[i], i + 1, b.exercise.name),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                    child: Row(children: [
                                      Text(
                                        'Serie ${i + 1}:',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${fmtNum(b.sets[i].weightKg)} kg × ${b.sets[i].reps} reps',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.edit_outlined, size: 16, color: AppColors.muted),
                                    ]),
                                  ),
                                ),
                            ]),
                          ),
                        ),
                      ),
                  ]);
                },
              ),
      ),
    );
  }

  Future<void> _editSet(BuildContext context, WidgetRef ref, WorkoutSet set, int setNum, String exerciseName) async {
    final weightCtrl = TextEditingController(text: fmtNum(set.weightKg));
    final repsCtrl = TextEditingController(text: '${set.reps}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Serie $setNum ($exerciseName)'),
        content: Row(children: [
          Expanded(
            child: TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Peso', suffixText: 'kg'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (ok == true) {
      final w = parseNum(weightCtrl.text) ?? 0.0;
      final r = int.tryParse(repsCtrl.text.trim()) ?? 0;
      await ref.read(workoutRepositoryProvider).updateSet(set.id, weightKg: w, reps: r);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serie actualizada')),
        );
      }
    }
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Eliminar entrenamiento?'),
            content: Text('Se borrará la sesión "$name" del historial de forma permanente.'),
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
