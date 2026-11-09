import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fit_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../workout/data/workout_repository.dart';
import '../data/routine_repository.dart';
import '../domain/routine_models.dart';

/// Badge colors cycled through the routine list so each routine is recognisable at a glance.
const _badgeColors = [AppColors.accent, AppColors.sky, AppColors.lime, AppColors.gold];

class RoutinesPage extends ConsumerWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ScreenHeader(title: l10n.navRoutines, actions: [
            HeaderAction(icon: Icons.list_alt_rounded, tooltip: l10n.exercisesTitle, onPressed: () => context.push('/exercises')),
            HeaderAction(icon: Icons.history_rounded, tooltip: l10n.historyTitle, onPressed: () => context.push('/history')),
            HeaderAction(
                icon: Icons.add_rounded, tooltip: l10n.routineNew, filled: true, onPressed: () => context.push('/routines/edit')),
          ]),
          Expanded(
            child: AsyncBody<List<RoutineSummary>>(
              value: ref.watch(routinesProvider),
              onRetry: () => ref.invalidate(routinesProvider),
              isEmpty: (l) => l.isEmpty,
              empty: EmptyState(
                icon: Icons.fitness_center_rounded,
                message: l10n.routinesEmpty,
                action: FilledButton.icon(
                  onPressed: () => context.push('/routines/edit'),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.routineNew),
                ),
              ),
              builder: (list) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  const _ActiveBanner(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(child: Text(l10n.myRoutines, style: Theme.of(context).textTheme.titleMedium)),
                      Text('${list.length}', style: const TextStyle(color: AppColors.muted)),
                    ]),
                  ),
                  for (var i = 0; i < list.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RoutineCard(list[i], _badgeColors[i % _badgeColors.length]),
                    ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Shown while an unfinished workout exists so it can be resumed.
class _ActiveBanner extends ConsumerWidget {
  const _ActiveBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(activeWorkoutProvider).value;
    if (w == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: 150,
        child: Panel(
          padding: EdgeInsets.zero,
          onTap: () => context.push('/workout/${w.id}'),
          child: StripeBackground(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xF20B0C0F), Color(0x330B0C0F)]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Tag(l10n.workoutInProgress, color: AppColors.lime),
                const Spacer(),
                Text(w.name.toUpperCase(), style: display(32, italic: true), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.play_circle_fill_rounded, color: AppColors.lime),
                  const SizedBox(width: 6),
                  Text(l10n.workoutContinue,
                      style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard(this.s, this.color);
  final RoutineSummary s;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = s.routine.name;
    final abbr = name.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÑáéíóúñ0-9]'), '');
    return Panel(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      onTap: () => context.push('/routines/edit?id=${s.routine.id}'),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
          child: Text(
            (abbr.length > 3 ? abbr.substring(0, 3) : abbr).toUpperCase(),
            style: display(22, color: AppColors.bg),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.toUpperCase(),
                style: display(21, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(l10n.routineExerciseCount(s.exerciseCount),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
        if (s.exerciseCount > 0)
          IconButton(
            tooltip: '${l10n.workoutStart}: $name',
            onPressed: () async {
              final id = await ref.read(workoutRepositoryProvider).startWorkout(s.routine.id);
              if (context.mounted) context.push('/workout/$id');
            },
            icon: const Icon(Icons.play_arrow_rounded),
            style: IconButton.styleFrom(
              fixedSize: const Size(44, 44),
              backgroundColor: AppColors.surfaceHigh,
              foregroundColor: AppColors.accent,
            ),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted),
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
